import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:exif/exif.dart';
import 'package:permission_handler/permission_handler.dart';
import 'photo_gallery_screen.dart';
import 'package:geo_gallery/services/image_location_database.dart';

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

  @override
  void initState() {
    super.initState();
    _imageLocationDatabase = ImageLocationDatabase();
    _initializeDatabase();
    //_requestGalleryPermissionAndSaveImages();
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
    final exifData = await readExifFromBytes(File(imagePath).readAsBytesSync());
    final dateTime = exifData['Image DateTime']?.printable ?? DateTime.now().toString();
    await GallerySaver.saveImage(imagePath);

    if (_currentPosition != null) {
      await _imageLocationDatabase.insertImage(
        imagePath,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        dateTime,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to database')),
      );
    }
  }

  void _requestGalleryPermissionAndSaveImages() async {
    final status = await Permission.photos.status;
    print('Gallery permission status: $status');

    if (status.isGranted) {
      print('Gallery permission is granted');
      await _loadAndSaveGalleryImages();
    } else {
      print('Gallery permission is not granted. Requesting permission...');
      final result = await Permission.photos.request();
      if (result.isGranted) {
        print('Gallery permission granted after request');
        await _loadAndSaveGalleryImages();
      } else {
        print('Gallery permission denied after request');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied to access gallery')),
        );
      }
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
                      FloatingActionButton(
                        onPressed: _openCamera,
                        heroTag: 'cameraBtn',
                        child: Icon(Icons.camera),
                      ),
                      SizedBox(height: 16.0),
                      FloatingActionButton(
                        onPressed: () async {
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
                        heroTag: 'galleryBtn',
                        child: Icon(Icons.photo_library),
                      ),
                      SizedBox(height: 16.0),
                      FloatingActionButton(
                        onPressed: () {},
                        heroTag: 'gridBtn',
                        child: Icon(Icons.grid_on),
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
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _goToLocation(value);
                              }
                            },
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
