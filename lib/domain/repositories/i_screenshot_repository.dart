// lib/domain/repositories/i_screenshot_repository.dart

import '../models/screenshot_model.dart';

abstract class IScreenshotRepository {
  Future<void> indexScreenshot(String filePath);

  Future<List<Screenshot>> searchScreenshots(String query);

  Future<Screenshot?> getScreenshotById(String id);

  Future<List<Screenshot>> getAllScreenshots();
}
