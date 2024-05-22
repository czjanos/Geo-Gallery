import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:photo_manager/photo_manager.dart' hide LatLng;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geo_gallery/services/image_location_database.dart';
import 'photo_gallery_screen.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late maps.GoogleMapController _mapController;
  late FlutterMapMath _flutterMapMath;
  Position? _currentPosition;
  TextEditingController _searchController = TextEditingController();
  late ImageLocationDatabase _imageLocationDatabase;
  Set<maps.Marker> _markers = {};
  bool _searchedLocationVisible = false;
  Timer? _reloadMarkersTimer;
  double _lastZoomLevel = 0.0;
  final Map<String, List<Map<String, dynamic>>> _clusteredMarkers = {};

  //Selection related
  bool _isDrawCircle = false;
  bool _isDrawRectangle = false;
  bool _isSelectedMarkerGalleryVisible = false;
  double _selectionCircleRadius = 10;
  maps.Circle _selectionCircle =
      const maps.Circle(circleId: CircleId('selectionCircle'), visible: false);
  maps.Polygon _selectionPolygon = const maps.Polygon(
      polygonId: maps.PolygonId('selectionPolygon'), visible: false);
  maps.LatLng _lastTappedLatLng = maps.LatLng(0, 0);
  List<maps.LatLng> _tappedLatLngs = [];
  Set<maps.Marker> _selectedMarkers = {};
  List<Map<String, dynamic>> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _imageLocationDatabase = ImageLocationDatabase();
    _flutterMapMath = FlutterMapMath();
    _initializeDatabase();
    _loadAndSaveGalleryImages();
    _getCurrentLocation();
  }

  void _initializeDatabase() async {
    await _imageLocationDatabase.initDatabase();
  }

  @override
  void dispose() {
    _reloadMarkersTimer?.cancel();
    super.dispose();
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
        print('Empty marker icon bytes for image: $imagePath');
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

  Future<void> _loadMarkersFromDatabase() async {
    if (_mapController == null) return;

    double zoom = await _mapController.getZoomLevel();
    if ((_lastZoomLevel - zoom).abs() < 2) return;

    _lastZoomLevel = zoom;

    final LatLngBounds visibleRegion = await _mapController.getVisibleRegion();
    final southwest = visibleRegion.southwest;
    final northeast = visibleRegion.northeast;

    final double minLat = southwest.latitude;
    final double maxLat = northeast.latitude;
    final double minLng = southwest.longitude;
    final double maxLng = northeast.longitude;

    List<Map<String, dynamic>> images = await _imageLocationDatabase
        .getImagesInBounds(minLat, maxLat, minLng, maxLng);

    _clusterMarkers(images);

    Set<maps.Marker> markers = Set<maps.Marker>();

    _clusteredMarkers.forEach((key, value) {
      final LatLng position = LatLng(
        value.fold(
                0.0, (prev, element) => prev + element['latitude'] as double) /
            value.length,
        value.fold(
                0.0, (prev, element) => prev + element['longitude'] as double) /
            value.length,
      );
      final int count = value.length;
      final BitmapDescriptor clusterIcon = BitmapDescriptor.defaultMarker;

      markers.add(maps.Marker(
        markerId: maps.MarkerId(position.toString()),
        position: position,
        icon: clusterIcon,
        onTap: () {
          _onMarkerTapped(value);
        },
        infoWindow: InfoWindow(
          title: 'Multiple Images Here',
          snippet: '$count images',
        ),
      ));
    });

    setState(() {
      _markers = markers;
    });
  }

  void _onMarkerTapped(List<Map<String, dynamic>> images) {
    Widget content = SingleChildScrollView(
      child: Column(
        children: images.map((image) {
          String imagePath = image['path'] as String;
          File imageFile = File(imagePath);

          if (imageFile.existsSync()) {
            return Image.file(imageFile);
          } else {
            return Text('Image not loaded.');
          }
        }).toList(),
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Images'),
          content: content,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Back'),
            ),
          ],
        );
      },
    );
  }

  void _loadMarkersFromDatabaseWithDelay() {
    _reloadMarkersTimer?.cancel();
    _reloadMarkersTimer = Timer(Duration(milliseconds: 500), () {
      _loadMarkersFromDatabase();
    });
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

  void _addClusterMarker() {
    _markers.clear();
    _markers.add(
      maps.Marker(
        markerId: maps.MarkerId('clusterMarker'),
        position: maps.LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: maps.InfoWindow(title: 'Multiple Images Here'),
        icon: maps.BitmapDescriptor.defaultMarkerWithHue(
          maps.BitmapDescriptor.hueYellow,
        ),
      ),
    );
  }

  void _clusterMarkers(List<Map<String, dynamic>> images) {
    _clusteredMarkers.clear();
    for (var image in images) {
      double lat = image['latitude'] as double;
      double lng = image['longitude'] as double;
      String imagePath = image['path'] as String;

      final key = '$lat-$lng';
      if (!_clusteredMarkers.containsKey(key)) {
        _clusteredMarkers[key] = [];
      }
      _clusteredMarkers[key]!.add(image);
    }
  }

  void _addMarkersToMap() {
    _loadMarkersFromDatabase();
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
        await _imageLocationDatabase.insertImage(
          pickedImage.path,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          DateTime.now().toString(),
        );

         await GallerySaver.saveImage(pickedImage.path).then((bool? success) {
          if (success == true) {
            print('Image saved to gallery');
          } else {
            print('Failed to save image to gallery');
          }
        });
      }
      _addMarkersToMap();
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
      if (file == null) {
        throw Exception("File is null.");
      }

      String originalImagePath = file.path;

      if (latitude != null && longitude != null && file != null) {
        await _imageLocationDatabase.insertImage(
          originalImagePath,
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

  void _toggleDrawCircle() {
    setState(() {
      _isDrawCircle = true;
      _isDrawRectangle = false;
    });
  }

  void _toggleDrawPolygon() {
    setState(() {
      _isDrawCircle = false;
      _updateSelectionCircle(visible: false);
      _isDrawRectangle = true;
    });
  }

  void _cancelAllDrawTool() {
    setState(() {
      _isDrawCircle = false;
      _isDrawRectangle = false;
      _tappedLatLngs = [];
      _updateSelectionCircle(visible: false);
    });
  }

  void _addLatLng(maps.LatLng latLng) {
    setState(() {
      if (_isDrawCircle) {
        _lastTappedLatLng = latLng;
        _updateSelectionCircle();
        _updateSelectionPolygon(visible: false);
      } else if (_isDrawRectangle) {
        _lastTappedLatLng = latLng;
        _updateSelectionCircle(visible: false);
        _tappedLatLngs.add(latLng);
        _updateSelectionPolygon();
      }
    });
  }

  void _updateSelectionPolygon({bool visible = true}) {
    Set<Marker> selectedMarkers = {};
    if (visible) {
      if (_selectionPolygon.points.length > 2) {
        maps.LatLng maxPos = _selectionPolygon.points[1];
        double maxDistance = 0;

        List<mp.LatLng> actLatLngList = _selectionPolygon.points
            .map((point) => mp.LatLng(point.latitude, point.longitude))
            .toList();
        for (maps.Marker marker in _markers) {
          if (mp.PolygonUtil.containsLocation(
              mp.LatLng(marker.position.latitude, marker.position.longitude),
              actLatLngList,
              true)) {
            selectedMarkers.add(marker);
            double distance = _flutterMapMath.distanceBetween(
                marker.position.latitude,
                marker.position.longitude,
                _selectionPolygon.points[0].latitude,
                _selectionPolygon.points[0].longitude,
                "meters");
            if (distance > maxDistance) {
              maxDistance = distance;
              maxPos = marker.position;
            }
            print('Polygon contains markers: ${selectedMarkers}');
          }
        }
        if (selectedMarkers.isNotEmpty) {
          _imageLocationDatabase
              .getImagesInBounds(
            _selectionPolygon.points[0].latitude,
            maxPos.latitude,
            _selectionPolygon.points[0].longitude,
            maxPos.longitude,
          )
              .then((images) {
            setState(() {
              print('Selected images: ${images}');
              _selectedImages = images;
            });
          }).onError((error, stackTrace) {
            setState(() {
              _selectedImages = [];
            });
          });
        } else {
          setState(() {
            _selectedMarkers = {};
            _selectedImages = [];
          });
        }
      }
    } else {
      setState(() {
        _selectedMarkers = {};
        _selectedImages = [];
        _tappedLatLngs = [];
      });
    }
    setState(() {
      _selectedMarkers = selectedMarkers;
      _selectionPolygon = maps.Polygon(
          polygonId: const maps.PolygonId('selectionPolygon'),
          strokeWidth: 2,
          fillColor: const Color(0xFF006491).withOpacity(0.2),
          consumeTapEvents: visible,
          onTap: () {
            print('Polygon tapped! ${_selectedImages}');
            _onMarkerTapped(_selectedImages);
          },
          visible: visible,
          points: _tappedLatLngs);
    });
  }

  void _updateSelectionCircle({bool visible = true}) {
    maps.LatLng maxDistancePos = const maps.LatLng(0, 0);
    double maxDistance = 0;

    Set<Marker> selectedMarkers = {};
    if (visible) {
      for (maps.Marker marker in _markers) {
        double distance = _flutterMapMath.distanceBetween(
            _selectionCircle.center.latitude,
            _selectionCircle.center.longitude,
            marker.position.latitude,
            marker.position.longitude,
            "meters");
        if (distance < _selectionCircleRadius) {
          if (maxDistance < distance) {
            maxDistance = distance;
            maxDistancePos = marker.position;
          }
          selectedMarkers.add(marker);
        }
      }
      if (selectedMarkers.isNotEmpty) {
        _imageLocationDatabase
            .getImagesInBounds(
          _selectionCircle.center.latitude,
          maxDistancePos.latitude,
          _selectionCircle.center.longitude,
          maxDistancePos.longitude,
        )
            .then((images) {
          setState(() {
            print('Selected images: ${images}');
            _selectedImages = images;
          });
        }).onError((error, stackTrace) {
          setState(() {
            _selectedImages = [];
          });
        });
      } else {
        setState(() {
          _selectedImages = [];
        });
      }
    } else {
      setState(() {
        _selectedImages = [];
      });
    }

    setState(() {
      _selectedMarkers = selectedMarkers;
      _selectionCircle = maps.Circle(
          circleId: const CircleId('selectionCircle'),
          center: _lastTappedLatLng,
          radius: _selectionCircleRadius,
          strokeWidth: 2,
          fillColor: const Color(0xFF006491).withOpacity(0.2),
          consumeTapEvents: visible,
          onTap: () {
            print('Circle tapped! ${_selectedImages}');
            _onMarkerTapped(_selectedImages);
          },
          visible: visible);
    });

    // _selectedMarkers = _markers.where((marker) {
    //   double distance = _flutterMapMath.distanceBetween(
    //       _selectionCircle.center.latitude,
    //       _selectionCircle.center.longitude,
    //       marker.position.latitude,
    //       marker.position.longitude,
    //       "meters");
    //   return distance < _selectionCircle.radius;
    // }).toSet();
    print('Selected markers: ${_selectedMarkers}');
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
                  onTap: (latLng) {
                    print(
                        'Tapped latitude: ${latLng.latitude}, longitude: ${latLng.longitude}');
                    _addLatLng(latLng);
                  },
                  circles: {_selectionCircle},
                  polygons:
                      _tappedLatLngs.isNotEmpty ? {_selectionPolygon} : {},
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
                    _loadMarkersFromDatabase();
                  },
                  onCameraMove: (maps.CameraPosition position) {
                    _loadMarkersFromDatabaseWithDelay();
                  },
                  onCameraMoveStarted: () {},
                  onCameraIdle: () {
                    _addMarkersToMap();
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
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          _toggleDrawCircle();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(16.0),
                        ),
                        child: Icon(Icons.add_circle),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          _toggleDrawPolygon();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(16.0),
                        ),
                        child: Icon(Icons.add_box),
                      ),
                    ],
                  ),
                ),
                _isDrawCircle
                    ? Positioned(
                        bottom: 80.0,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Slider(
                                  value: _selectionCircleRadius,
                                  max: 1000,
                                  divisions: 100,
                                  label:
                                      _selectionCircleRadius.round().toString(),
                                  onChanged: (double value) {
                                    setState(() {
                                      _selectionCircleRadius = value;
                                      _updateSelectionCircle();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.cancel),
                                  onPressed: () {
                                    _cancelAllDrawTool();
                                  },
                                ),
                              ],
                            )))
                    : const SizedBox(),
                _isDrawRectangle
                    ? Positioned(
                        bottom: 80.0,
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Drawing polygon"),
                                IconButton(
                                  icon: Icon(Icons.cancel),
                                  onPressed: () {
                                    _cancelAllDrawTool();
                                  },
                                ),
                              ],
                            )))
                    : const SizedBox(),
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
