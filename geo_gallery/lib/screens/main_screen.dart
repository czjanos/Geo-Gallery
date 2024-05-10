import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:exif/exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geo_gallery/services/image_location_database.dart';
import 'photo_gallery_screen.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:photo_manager/photo_manager.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late maps.GoogleMapController _mapController;
  Position? _currentPosition;
  TextEditingController _searchController = TextEditingController();
  late ImageLocationDatabase _imageLocationDatabase;
  Set<maps.Marker> _markers = {};
  bool _searchedLocationVisible = false;

  @override
  void initState() {
    super.initState();
    _imageLocationDatabase = ImageLocationDatabase();
    _initializeDatabase();
    _loadAndSaveGalleryImages();
    _getCurrentLocation();
  }

  void _initializeDatabase() async {
    await _imageLocationDatabase.initDatabase();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error fetching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location')),
      );
    }
  }

  Future<Uint8List> _getImageBytes(String path) async {
    try {
      final File imageFile = File(path);
      if (!imageFile.existsSync()) {
        print('Image file not found: $path');
        return Uint8List(0);
      }

      return await imageFile.readAsBytes();
    } catch (e) {
      print('Error reading image file: $e');
      return Uint8List(0);
    }
  }

  Future<maps.BitmapDescriptor> _createCustomMarker(String imagePath) async {
    try {
      final Uint8List markerIconBytes = await _getImageBytes(imagePath);
      if (markerIconBytes.isEmpty) {
        print('Empty marker icon bytes.');
        return maps.BitmapDescriptor.defaultMarker;
      }

      double zoom = await _mapController.getZoomLevel();
      double markerSize = 24.0 * (zoom / 12.0).clamp(10.0, 10.0).toDouble();

      final ui.Codec codec = await ui.instantiateImageCodec(markerIconBytes,
          targetWidth: markerSize.toInt(), targetHeight: markerSize.toInt());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final Uint8List resizedIconBytes =
          (await frameInfo.image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();

      final maps.BitmapDescriptor customIcon =
          maps.BitmapDescriptor.fromBytes(resizedIconBytes);

      return customIcon;
    } catch (e) {
      print('Error creating custom marker: $e');
      return maps.BitmapDescriptor.defaultMarker;
    }
  }

  Future<Uint8List> _getBytesFromAsset(
      Uint8List markerIconBytes, int width, int height) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(markerIconBytes,
          targetWidth: width, targetHeight: height);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final Uint8List data =
          (await frameInfo.image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
      return data;
    } catch (e) {
      print('Error decoding image: $e');
      return Uint8List(0);
    }
  }

  Future<void> _loadMarkersFromDatabase() async {
    List<Map<String, dynamic>> images =
        await _imageLocationDatabase.getAllImages();
    double zoom = await _mapController.getZoomLevel();

    Set<maps.Marker> markers = Set<maps.Marker>();

    for (var image in images) {
      double lat = image['latitude'] as double;
      double lng = image['longitude'] as double;
      String imagePath = image['path'] as String;

      maps.BitmapDescriptor customIcon = await _createCustomMarker(imagePath);

      maps.Marker marker = maps.Marker(
        markerId: maps.MarkerId(imagePath),
        position: maps.LatLng(lat, lng),
        infoWindow: maps.InfoWindow(title: 'Image Marker', snippet: imagePath),
        icon: customIcon,
        anchor: Offset(0.5, 0.5),
        zIndex: (10 - zoom).toDouble(),
        onTap: () {
          print('Marker tapped: $imagePath');
        },
      );

      markers.add(marker);
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<Set<maps.Marker>> _createMarkers(
      List<Map<String, dynamic>> images, double zoom) async {
    List<maps.Marker> markers = [];

    for (var image in images) {
      double lat = image['latitude'] as double;
      double lng = image['longitude'] as double;
      String imagePath = image['path'] as String;

      maps.BitmapDescriptor customIcon = await _createCustomMarker(imagePath);

      double imageSize = 24 * (zoom / 122);

      maps.Marker marker = maps.Marker(
        markerId: maps.MarkerId(imagePath),
        position: maps.LatLng(lat, lng),
        infoWindow: maps.InfoWindow(title: 'Image Marker', snippet: imagePath),
        icon: customIcon,
        anchor: Offset(0.5, 0.5),
        zIndex: (21 - zoom).toDouble(),
        onTap: () {
          print('Marker tapped: $imagePath');
        },
      );

      markers.add(marker);
    }

    return Set<maps.Marker>.of(markers);
  }

  void _addMarkerAtLocation(double latitude, double longitude) {
    setState(() {
      if (!_searchedLocationVisible) {
        _markers.clear();
        _markers.add(
          maps.Marker(
            markerId: maps.MarkerId('searchedLocation'),
            position: maps.LatLng(latitude, longitude),
            infoWindow: maps.InfoWindow(title: 'Searched Location'),
            icon: maps.BitmapDescriptor.defaultMarkerWithHue(
                maps.BitmapDescriptor.hueAzure),
          ),
        );
        _searchedLocationVisible = true;
      } else {
        return;
      }
    });
  }

  void _openCamera() async {
    try {
      final XFile? pickedImage = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (pickedImage != null) {
       // await _saveImageToDatabase(pickedImage.path);
      }
    } catch (e) {
      print('Error opening camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening camera')),
      );
    }
  }

Future<void> _saveImageToDatabase(AssetEntity asset) async {
  try {
    double? latitude = asset.latitude;
    double? longitude = asset.longitude;

    File? file = await asset.file;

    if (latitude != null && longitude != null && file != null) {
      await _imageLocationDatabase.insertImage(
        '', 
        latitude,
        longitude,
        asset.createDateTime.toString(),
      );
    } else {
      throw Exception("Latitude, longitude, or file is null.");
    }
  } catch (e) {
    print('Error saving image to database: $e');
    ScaffoldMessenger.of(context)?.showSnackBar(
      SnackBar(content: Text('Error saving image to database')),
    );
  }
}


Future<void> _loadAndSaveGalleryImages() async {
  try {
    final List<AssetEntity> mediaList = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    )
        .then((value) => value[0].getAssetListRange(
              start: 0,
              end: 1000000,
            ))
        .then((value) => value.toList());

    for (AssetEntity media in mediaList) {
      await _saveImageToDatabase(media);
    }

  } catch (e) {
    print('Error loading or saving images from gallery: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading or saving images from gallery')),
    );
  }
}


  void _goToLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        _mapController.animateCamera(
          maps.CameraUpdate.newLatLngZoom(
            maps.LatLng(location.latitude!, location.longitude!),
            14.0,
          ),
        );
        _addMarkerAtLocation(location.latitude!, location.longitude!);

        _searchedLocationVisible = false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No results found')),
        );
      }
    } catch (e) {
      print('Error during search: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during search')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geo Gallery'),
      ),
      body: _currentPosition != null
          ? Stack(
              children: [
                maps.GoogleMap(
                  mapType: maps.MapType.normal,
                  initialCameraPosition: maps.CameraPosition(
                    target: maps.LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  markers: _markers,
                  onMapCreated: (maps.GoogleMapController controller) {
                    _mapController = controller;
                    //_loadMarkersFromDatabase();
                  },
                  onCameraMove: (maps.CameraPosition position) {
                    //_loadMarkersFromDatabase();
                  },
                ),
                Positioned(
                  top: 20.0,
                  right: 20.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _openCamera,
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(16.0),
                        ),
                        child: Icon(Icons.camera_alt),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () async {
                          //_loadMarkersFromDatabase();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoGalleryScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(16.0),
                        ),
                        child: Icon(Icons.photo_library),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPosition != null) {
                            _mapController.animateCamera(
                              maps.CameraUpdate.newLatLngZoom(
                                maps.LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                14.0,
                              ),
                            );
                            _markers.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(16.0),
                        ),
                        child: Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20.0,
                  left: 20.0,
                  right: 20.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  _goToLocation(value);
                                }
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            String query = _searchController.text;
                            if (query.isNotEmpty) {
                              _goToLocation(query);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
