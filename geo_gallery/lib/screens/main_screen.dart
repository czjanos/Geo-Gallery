import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:exif/exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geo_gallery/services/image_location_database.dart';
import 'photo_gallery_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  TextEditingController _searchController = TextEditingController();
  late ImageLocationDatabase _imageLocationDatabase;
  Set<Marker> _markers = {};

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

  Future<void> _loadMarkersFromDatabase() async {
    List<Map<String, dynamic>> images = await _imageLocationDatabase.getAllImages();
    setState(() {
      _markers = _createMarkers(images);
    });
  }

  Set<Marker> _createMarkers(List<Map<String, dynamic>> images) {
    return images.map((image) {
      double lat = image['latitude'] as double;
      double lng = image['longitude'] as double;
      String imagePath = image['path'] as String;

      return Marker(
        markerId: MarkerId(imagePath),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: 'Image Marker', snippet: imagePath),
        icon: BitmapDescriptor.defaultMarker,
      );
    }).toSet();
  }

  void _addMarkerAtLocation(double latitude, double longitude) {
    setState(() {
      _markers.clear(); // Töröljük az összes jelenlegi markert
      _markers.add(
        Marker(
          markerId: MarkerId('searchedLocation'),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(title: 'Searched Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
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
        await _saveImageToDatabase(pickedImage.path);
      }
    } catch (e) {
      print('Error opening camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening camera')),
      );
    }
  }

  Future<void> _saveImageToDatabase(String imagePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      final String savedImagePath = '${appDir.path}/$imageName.jpg';

      await File(imagePath).copy(savedImagePath);

      final exifData = await readExifFromBytes(File(savedImagePath).readAsBytesSync());
      final dateTime = exifData['Image DateTime']?.printable ?? DateTime.now().toString();

      await GallerySaver.saveImage(savedImagePath);

      if (_currentPosition != null) {
        await _imageLocationDatabase.insertImage(
          savedImagePath,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          dateTime,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to database')),
        );
      }
    } catch (e) {
      print('Error saving image to database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image to database')),
      );
    }
  }

  Future<void> _loadAndSaveGalleryImages() async {
    try {
      final List<XFile>? galleryImages = await ImagePicker().pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (galleryImages != null && galleryImages.isNotEmpty) {
        await _imageLocationDatabase.deleteAllImages();

        for (XFile image in galleryImages) {
          await _saveImageToDatabase(image.path);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Images saved to database')),
        );
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
          CameraUpdate.newLatLngZoom(
            LatLng(location.latitude!, location.longitude!),
            14.0,
          ),
        );
        _addMarkerAtLocation(location.latitude!, location.longitude!);
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
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
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
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
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
                          _loadMarkersFromDatabase();
                          List<Map<String, dynamic>> images =
                              await _imageLocationDatabase.getAllImages();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PhotoGalleryScreen(images: images),
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
                              CameraUpdate.newLatLngZoom(
                                LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                14.0,
                              ),
                            );
                            _markers.clear(); // Töröljük az összes markert
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
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
