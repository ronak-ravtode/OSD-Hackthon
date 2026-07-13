// lib/data/repositories/local_screenshot_repository.dart

import '../../domain/models/screenshot_model.dart';
import '../../domain/repositories/i_screenshot_repository.dart';
import '../database/database_helper.dart';
import '../services/ocr_service.dart';

class LocalScreenshotRepository implements IScreenshotRepository {
  final DatabaseHelper _db;
  final OcrService _ocr;

  const LocalScreenshotRepository(this._db, this._ocr);

  @override
  Future<void> indexScreenshot(String filePath) async {
    final String text = await _ocr.extractText(filePath);
    final Screenshot screenshot = Screenshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: filePath,
      extractedText: text,
      category: 'other',
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
}
