import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'photo_gallery_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  bool _isMapCreated = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error fetching location: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during search')),
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
  
      }
    } catch (e) {
      print('Error opening camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening camera')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          if (_currentPosition != null) {
            return Stack(
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
                    _isMapCreated = true;
                  },
                ),
                Positioned(
                  top: 80.0,
                  right: 20.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Handle settings button press
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Icon(Icons.settings),
                      ),
                      SizedBox(height: 8.0),
                      ElevatedButton(
                        onPressed: _openCamera,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Icon(Icons.camera),
                      ),
                      SizedBox(height: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoGalleryScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Icon(Icons.photo_library),
                      ),
                      SizedBox(height: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          // Handle grid button press
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
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
                          icon: Icon(Icons.location_on),
                          onPressed: () {
                            // Return to user's current location
                            if (_currentPosition != null && _isMapCreated) {
                              _mapController.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                    ),
                                    zoom: 14.0,
                                  ),
                                ),
                              );
                            }
                          },
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
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
