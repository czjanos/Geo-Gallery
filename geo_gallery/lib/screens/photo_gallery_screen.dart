import 'package:flutter/material.dart';
import 'package:exif/exif.dart';
import 'dart:io';
import 'dart:typed_data';

class PhotoGalleryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> images;

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
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        return _buildImageWidget(widget.images[index]);
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

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.memory(
                bytes,
                key: ValueKey(imagePath),
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 8.0),
            FutureBuilder<String>(
              future: _getImageCreationDate(imagePath),
              builder: (context, dateSnapshot) {
                if (dateSnapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox.shrink();
                } else if (dateSnapshot.hasError) {
                  return Text('Error fetching date');
                }

                String? creationDate = dateSnapshot.data;
                return creationDate != null
                    ? Text(
                        'Created: $creationDate',
                        style: TextStyle(fontSize: 12.0),
                      )
                    : SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Uint8List> _getImageBytes(String imagePath) async {
    File imageFile = File(imagePath);
    return await imageFile.readAsBytes();
  }

  Future<String> _getImageCreationDate(String imagePath) async {
    try {
      final tags = await readExifFromBytes(File(imagePath).readAsBytesSync());
      if (tags == null || !tags.containsKey('Image DateTime')) {
        return 'Unknown date';
      }
      return tags['Image DateTime']?.printable ?? 'Unknown date';
    } catch (e) {
      print('Error reading image metadata: $e');
      return 'Unknown date';
    }
  }
}
