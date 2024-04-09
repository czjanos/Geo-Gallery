import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({Key? key}) : super(key: key);

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<XFile>? _imageFiles = [];

  @override
  void initState() {
    super.initState();
    _loadImagesFromGallery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Gallery'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return _imageFiles != null && _imageFiles!.isNotEmpty
        ? GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: _imageFiles!.length,
            itemBuilder: (context, index) {
              if (index > 0) {
                final prevImage = _imageFiles![index - 1];
                final currImage = _imageFiles![index];
                if (_shouldInsertSpace(prevImage, currImage)) {
                  return Column(
                    children: [
                      SizedBox(height: 20.0),
                      _buildImageWidget(currImage.path),
                    ],
                  );
                }
              }
              return _buildImageWidget(_imageFiles![index].path);
            },
          )
        : Center(
            child: CircularProgressIndicator(),
          );
  }

  Widget _buildImageWidget(String filePath) {
    return Image.file(
      File(filePath),
      key: ValueKey(filePath),
      fit: BoxFit.cover,
    );
  }

  Future<void> _loadImagesFromGallery() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage();
    if (pickedImages != null && pickedImages.isNotEmpty) {
      setState(() {
        _imageFiles = _sortImagesByDate(pickedImages);
      });
    }
  }

  List<XFile> _sortImagesByDate(List<XFile> images) {
    images.sort((a, b) => File(a.path).lastModifiedSync().compareTo(File(b.path).lastModifiedSync()));
    return images;
  }

  bool _shouldInsertSpace(XFile prevImage, XFile currImage) {
    final prevDate = File(prevImage.path).lastModifiedSync();
    final currDate = File(currImage.path).lastModifiedSync();
    final differenceInDays = currDate.difference(prevDate).inDays;
    
    return differenceInDays > 1;
  }
}
