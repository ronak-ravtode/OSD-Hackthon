// lib/presentation/providers/screenshot_provider.dart

import 'package:flutter/foundation.dart';

import '../../domain/models/screenshot_model.dart';
import '../../domain/repositories/i_screenshot_repository.dart';

class ScreenshotProvider extends ChangeNotifier {
  final IScreenshotRepository _repository;

  ScreenshotProvider(this._repository);

  List<Screenshot> screenshots = [];
  List<Screenshot> searchResults = [];
  bool isLoading = false;
  String? error;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      screenshots = await _repository.getAllScreenshots();
    } on Exception catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
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

  Future<void> indexScreenshot(String path) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _repository.indexScreenshot(path);
      await loadAll();
    } on Exception catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}
