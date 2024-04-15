import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:exif/exif.dart';
import 'dart:typed_data';

class PhotoGalleryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> images; // Definiáljuk a 'images' paramétert

  const PhotoGalleryScreen({Key? key, required this.images}) : super(key: key);

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
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
      itemCount: widget.images.length, // Hivatkozás a widget.images-re
      itemBuilder: (context, index) {
        return _buildImageWidget(widget.images[index]); // Hivatkozás a widget.images-re
      },
    );
  }

  Widget _buildImageWidget(Map<String, dynamic> imageData) {
    String imagePath = imageData['path'];

    return FutureBuilder<Uint8List>(
      future: _getImageBytes(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading image');
        }

        Uint8List? bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return Text('Invalid image data');
        }

        return Image.memory(
          bytes,
          key: ValueKey(imagePath),
          fit: BoxFit.cover,
        );
      },
    );
  }

  Future<Uint8List> _getImageBytes(String imagePath) async {
    File imageFile = File(imagePath);
    return await imageFile.readAsBytes();
  }
}
