// lib/data/repositories/local_screenshot_repository.dart

// lib/data/repositories/local_screenshot_repository.dart

import '../../domain/models/screenshot_model.dart';
import '../../domain/models/album_model.dart';
import '../../domain/repositories/i_screenshot_repository.dart';
import '../database/database_helper.dart';
import '../services/ocr_service.dart';
import '../services/category_classifier.dart';

class LocalScreenshotRepository implements IScreenshotRepository {
  final DatabaseHelper _db;
  final OcrService _ocr;

  const LocalScreenshotRepository(this._db, this._ocr);

  @override
  Future<void> indexScreenshot(String filePath) async {
    final String text = await _ocr.extractText(filePath);
    final String category = CategoryClassifier.classify(text, filePath);
    final Screenshot screenshot = Screenshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: filePath,
      extractedText: text,
      category: category,
      timestamp: DateTime.now(),
    );
    await _db.insertScreenshot(screenshot);
  }

  @override
  Future<List<Screenshot>> searchScreenshots(String query) {
    return _db.searchScreenshots(query);
  }

  @override
  Future<Screenshot?> getScreenshotById(String id) {
    return _db.getById(id);
  }

  @override
  Future<List<Screenshot>> getAllScreenshots() {
    return _db.getAllScreenshots();
  }

  @override
  Future<void> deleteScreenshot(String id) {
    return _db.deleteScreenshot(id);
  }

  @override
  Future<List<Album>> getAllAlbums() {
    return _db.getAllAlbums();
  }

  @override
  Future<void> createAlbum(Album album) {
    return _db.createAlbum(album);
  }

  @override
  Future<void> deleteAlbum(String id) {
    return _db.deleteAlbum(id);
  }

  @override
  Future<void> addScreenshotToAlbum(String albumId, String screenshotId) {
    return _db.addScreenshotToAlbum(albumId, screenshotId);
  }

  @override
  Future<void> removeScreenshotFromAlbum(String albumId, String screenshotId) {
    return _db.removeScreenshotFromAlbum(albumId, screenshotId);
  }

  @override
  Future<List<Screenshot>> getScreenshotsForAlbum(String albumId) {
    return _db.getScreenshotsForAlbum(albumId);
  }
}
