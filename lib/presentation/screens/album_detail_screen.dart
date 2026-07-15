// lib/presentation/screens/album_detail_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/screenshot_model.dart';
import '../../domain/models/album_model.dart';
import '../providers/screenshot_provider.dart';
import 'screenshot_detail_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album? customAlbum; // null if predefined category
  final String? categoryKey; // null if custom album
  final String title;

  const AlbumDetailScreen({
    super.key,
    this.customAlbum,
    this.categoryKey,
    required this.title,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Screenshot> _photos = <Screenshot>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final ScreenshotProvider provider = context.read<ScreenshotProvider>();
    if (widget.customAlbum != null) {
      final List<Screenshot> res =
          await provider.getScreenshotsForAlbum(widget.customAlbum!.id);
      if (mounted) {
        setState(() {
          _photos = res;
          _loading = false;
        });
      }
    } else if (widget.categoryKey != null) {
      // Predefined category
      final List<Screenshot> res = provider.screenshots
          .where((Screenshot s) => s.category == widget.categoryKey)
          .toList();
      if (mounted) {
        setState(() {
          _photos = res;
          _loading = false;
        });
      }
    } else {
      // "All photos" or "Camera" — no album, no category
      List<Screenshot> res = provider.screenshots;
      if (widget.title == 'Camera') {
        res = provider.screenshots
            .where((Screenshot s) =>
                s.filePath.toLowerCase().contains('camera'))
            .toList();
      }
      if (mounted) {
        setState(() {
          _photos = res;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(
                  child: Text(
                    'No photos in this album.',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (BuildContext ctx, int i) {
                    final Screenshot s = _photos[i];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ScreenshotDetailScreen(screenshot: s),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.grey[900],
                          child: (s.filePath.isNotEmpty && !kIsWeb)
                              ? Image.file(
                                  File(s.filePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                      Icons.image_not_supported,
                                      size: 32),
                                )
                              : const Icon(Icons.image, size: 32),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
