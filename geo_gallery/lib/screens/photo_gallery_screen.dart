import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class PhotoGalleryScreen extends StatefulWidget {
  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<AssetEntity> _mediaList = [];
  List<Map<String, dynamic>> _images = [];
  bool _loading = false;
  int _currentPage = 0;
  int _pageSize = 20;
  bool _allLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAndDisplayImages();
  }

  Future<void> _loadAndDisplayImages() async {
    setState(() {
      _loading = true;
    });

    try {
      final List<AssetEntity> mediaList = await _fetchMedia();
      if (mediaList.isEmpty) {
        _allLoaded = true;
      }
      _mediaList.addAll(mediaList);

      for (AssetEntity media in mediaList) {
        await _displayImage(media);
      }
    } catch (e) {
      print('Error loading images:  $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<List<AssetEntity>> _fetchMedia() async {
    final paths = await PhotoManager.getAssetPathList(type: RequestType.image);
    final mediaList = await paths[0].getAssetListRange(
      start: _currentPage * _pageSize,
      end: (_currentPage + 1) * _pageSize,
    );
    return mediaList;
  }

  Future<void> _displayImage(AssetEntity asset) async {
    try {
      final latitude = asset.latitude;
      final longitude = asset.longitude;
      final createDateTime = asset.createDateTime?.toString();

      if (latitude != null && longitude != null) {
        final bytes = await asset.originBytes;
        if (bytes != null) {
          final imageData = {'bytes': bytes, 'date': createDateTime};
          setState(() {
            _images.add(imageData);
          });
        }
      }
    } catch (e) {
      print('Error loading images:  $e');
    }
  }

  void _loadMoreImages() {
    if (!_loading && !_allLoaded) {
      _currentPage++;
      _loadAndDisplayImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Gallery'),
      ),
      body: _loading && _images.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _buildImageList(),
    );
  }

  Widget _buildImageList() {
    return _images.isEmpty
        ? Center(
            child: Text('No images to display'),
          )
        : NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (!_loading &&
                  !_allLoaded &&
                  scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent) {
                _loadMoreImages();
              }
              return true;
            },
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return _buildImageWidget(_images[index]);
              },
            ),
          );
  }

  Widget _buildImageWidget(Map<String, dynamic> imageData) {
    final bytes = imageData['bytes'];
    final createDateTime = imageData['date'];

    return Card(
    elevation: 4.0,
    child: Image.memory(
      bytes,
      fit: BoxFit.cover,
    ),
  );
  }
}
