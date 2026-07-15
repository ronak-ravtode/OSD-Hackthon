// lib/domain/repositories/i_screenshot_repository.dart

import '../models/screenshot_model.dart';
import '../models/album_model.dart';

abstract class IScreenshotRepository {
  Future<void> indexScreenshot(String filePath);

  Future<List<Screenshot>> searchScreenshots(String query);

  Future<Screenshot?> getScreenshotById(String id);

  Future<List<Screenshot>> getAllScreenshots();

  Future<void> deleteScreenshot(String id);

  Future<List<Album>> getAllAlbums();

  Future<void> createAlbum(Album album);

  Future<void> deleteAlbum(String id);

  Future<void> addScreenshotToAlbum(String albumId, String screenshotId);

  Future<void> removeScreenshotFromAlbum(String albumId, String screenshotId);

  Future<List<Screenshot>> getScreenshotsForAlbum(String albumId);
}
