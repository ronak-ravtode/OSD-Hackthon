// lib/data/services/background_indexer.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class BackgroundIndexer {
  const BackgroundIndexer._();

  static const List<String> _scanPaths = <String>[
    '/storage/emulated/0/Pictures/Screenshots',
    '/storage/emulated/0/DCIM/Screenshots',
    '/storage/emulated/0/Screenshots',
  ];

  /// Scans known screenshot directories.
  /// Returns file paths not yet in [indexedPaths].
  static Future<List<String>> findNewScreenshots(
    Set<String> indexedPaths,
  ) async {
    if (kIsWeb) return <String>[];

    final List<String> newFiles = <String>[];

    for (final String dirPath in _scanPaths) {
      final Directory dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      try {
        final List<FileSystemEntity> entities =
            await dir.list().toList();
        for (final FileSystemEntity entity in entities) {
          if (entity is! File) continue;
          final String ext =
              entity.path.split('.').last.toLowerCase();
          if (!_isImage(ext)) continue;
          if (!indexedPaths.contains(entity.path)) {
            newFiles.add(entity.path);
          }
        }
      } on FileSystemException catch (_) {
        // Directory not accessible, skip
      }
    }

    return newFiles;
  }

  static bool _isImage(String ext) {
    return const <String>{
      'png', 'jpg', 'jpeg', 'webp', 'bmp',
    }.contains(ext);
  }
}
