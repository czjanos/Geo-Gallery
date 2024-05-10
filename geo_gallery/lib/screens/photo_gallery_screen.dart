import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'dart:io';

class PhotoGalleryScreen extends StatefulWidget {
  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<Map<String, dynamic>> _images = [];

  @override
  void initState() {
    super.initState();
    _loadAndDisplayImages();
  }

  Future<void> _loadAndDisplayImages() async {
    try {
      final List<AssetEntity> mediaList = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      ).then((value) => value[0].getAssetListRange(
            start: 0,
            end: 1000000,
          ));

      for (AssetEntity media in mediaList) {
        await _displayImage(media);
      }
    } catch (e) {
      print('Error loading images: $e');
    }
  }

  Future<void> _displayImage(AssetEntity asset) async {
    try {
      double? latitude = asset.latitude;
      double? longitude = asset.longitude;
      String? createDateTime = asset.createDateTime?.toString();

      if (latitude != null && longitude != null) {
        File? file = await asset.file;
        if (file != null) {
          Uint8List bytes = await file.readAsBytes();
          Map<String, dynamic> imageData = {
            'bytes': bytes,
            'date': createDateTime,
          };
          setState(() {
            _images.add(imageData);
          });
        }
      }
    } catch (e) {
      print('Error displaying image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Gallery'),
      ),
      body: _buildImageGrid(),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        return _buildImageWidget(_images[index]);
      },
    );
  }

  Widget _buildImageWidget(Map<String, dynamic> imageData) {
    Uint8List bytes = imageData['bytes'];
    String? createDateTime = imageData['date'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'Created: ${createDateTime ?? ''}',
          style: TextStyle(fontSize: 12.0),
        ),
      ],
    );
  }
}
