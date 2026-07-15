// lib/presentation/providers/screenshot_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../core/utils/duplicate_detector.dart';
import '../../data/services/background_indexer.dart';
import '../../domain/models/screenshot_model.dart';
import '../../domain/models/album_model.dart';
import '../../domain/repositories/i_screenshot_repository.dart';

class ScreenshotProvider extends ChangeNotifier {
  final IScreenshotRepository _repository;

  ScreenshotProvider(this._repository);

  List<Screenshot> screenshots = [];
  List<Screenshot> searchResults = [];
  List<Album> albums = [];
  final Set<String> selectedIds = <String>{};
  bool isLoading = false;
  String? error;

  bool get isSelectionMode => selectedIds.isNotEmpty;

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll(List<String> ids) {
    selectedIds.addAll(ids);
    notifyListeners();
  }

  void deselectAll(List<String> ids) {
    selectedIds.removeAll(ids);
    notifyListeners();
  }

  void clearSelection() {
    selectedIds.clear();
    notifyListeners();
  }

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      screenshots = await _repository.getAllScreenshots();
      await loadAlbumsInternal();
    } on Exception catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAlbums() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await loadAlbumsInternal();
    } on Exception catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAlbumsInternal() async {
    albums = await _repository.getAllAlbums();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      searchResults = await _repository.searchScreenshots(query);
    } on Exception catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    searchResults = [];
    error = null;
    notifyListeners();
  }

  Future<bool> indexScreenshot(String path) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final bool isDup = await _isDuplicate(path);
      if (isDup) {
        isLoading = false;
        notifyListeners();
        return false;
      }
      await _repository.indexScreenshot(path);
      await loadAll();
      return true;
    } on Exception catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _isDuplicate(String newPath) async {
    if (kIsWeb) {
      return screenshots.any((Screenshot s) => s.filePath == newPath);
    }
    final File newFile = File(newPath);
    if (!await newFile.exists()) return false;
    final int newSize = await newFile.length();

    for (final Screenshot s in screenshots) {
      final File existingFile = File(s.filePath);
      if (!await existingFile.exists()) continue;
      final int existingSize = await existingFile.length();
      if (newSize == existingSize) {
        final Uint8List newBytes = await newFile.readAsBytes();
        final Uint8List existingBytes = await existingFile.readAsBytes();
        if (listEquals(newBytes, existingBytes)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> deleteScreenshot(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _repository.deleteScreenshot(id);
      await loadAll();
    } on Exception catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createAlbum(String name) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final Album album = Album(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: DateTime.now(),
      );
      await _repository.createAlbum(album);
      await loadAlbumsInternal();
    } on Exception catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAlbum(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _repository.deleteAlbum(id);
      await loadAlbumsInternal();
    } on Exception catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addScreenshotToAlbum(String albumId, String screenshotId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _repository.addScreenshotToAlbum(albumId, screenshotId);
    } on Exception catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMultipleScreenshotsToAlbum(String albumId, List<String> screenshotIds) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      for (final String id in screenshotIds) {
        await _repository.addScreenshotToAlbum(albumId, id);
      }
    } on Exception catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeScreenshotFromAlbum(String albumId, String screenshotId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _repository.removeScreenshotFromAlbum(albumId, screenshotId);
    } on Exception catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Screenshot>> getScreenshotsForAlbum(String albumId) async {
    try {
      return await _repository.getScreenshotsForAlbum(albumId);
    } on Exception catch (e) {
      error = e.toString();
      return <Screenshot>[];
    }
  }

  Future<void> deleteMultipleScreenshots(List<String> ids) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      for (final String id in ids) {
        await _repository.deleteScreenshot(id);
      }
      selectedIds.clear();
      await loadAll();
    } on Exception catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<int> scanForNewScreenshots() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final Set<String> indexed = screenshots
          .map((Screenshot s) => s.filePath)
          .toSet();
      final List<String> newFiles =
          await BackgroundIndexer.findNewScreenshots(indexed);
      int count = 0;
      for (final String path in newFiles) {
        await _repository.indexScreenshot(path);
        count++;
      }
      await loadAll();
      return count;
    } on Exception catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return 0;
    }
  }

  List<List<Screenshot>> findDuplicateGroups() {
    final List<List<Screenshot>> groups = <List<Screenshot>>[];
    final Set<int> visited = <int>{};

    for (int i = 0; i < screenshots.length; i++) {
      if (visited.contains(i)) continue;
      final List<Screenshot> group = <Screenshot>[screenshots[i]];
      for (int j = i + 1; j < screenshots.length; j++) {
        if (visited.contains(j)) continue;
        if (DuplicateDetector.isDuplicate(
          screenshots[i].extractedText,
          screenshots[j].extractedText,
        )) {
          group.add(screenshots[j]);
          visited.add(j);
        }
      }
      if (group.length > 1) {
        groups.add(group);
        visited.add(i);
      }
    }
    return groups;
  }
}
