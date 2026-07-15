// lib/data/database/database_helper.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/screenshot_model.dart';
import '../../domain/models/album_model.dart';

class DatabaseHelper {
  static const String _dbName = 'snap_search_v2.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'screenshots';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;
  
  // In-memory fallback database for Web
  final List<Screenshot> _webMockDb = [];
  final List<Album> _webMockAlbums = [];
  final List<Map<String, String>> _webMockAlbumScreenshots = [];

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite is not supported on Web. Use web mockup.');
    }
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onOpen: (Database db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS albums (
            id TEXT PRIMARY KEY,
            name TEXT UNIQUE,
            createdAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS album_screenshots (
            album_id TEXT,
            screenshot_id TEXT,
            PRIMARY KEY (album_id, screenshot_id)
          )
        ''');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE VIRTUAL TABLE $_tableName
      USING fts4(
        id,
        filePath,
        extractedText,
        category,
        timestamp
      )
    ''');
  }

  Future<void> insertScreenshot(Screenshot s) async {
    if (kIsWeb) {
      _webMockDb.add(s);
      return;
    }
    final db = await database;
    try {
      await db.insert(_tableName, s.toMap());
    } on DatabaseException catch (e) {
      throw Exception('DB insert failed: ${e.toString()}');
    }
  }

  Future<List<Screenshot>> searchScreenshots(String query) async {
    final sanitized =
        query.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    if (sanitized.isEmpty) return getAllScreenshots();

    if (kIsWeb) {
      final lowercaseWords = sanitized.toLowerCase().split(RegExp(r'\s+'));
      return _webMockDb.where((s) {
        final text = s.extractedText.toLowerCase();
        final path = s.filePath.toLowerCase();
        return lowercaseWords.every((w) => text.contains(w) || path.contains(w));
      }).toList();
    }

    final db = await database;
    try {
      final words = sanitized.split(RegExp(r'\s+'));
      final matchQuery = words.map((w) => '$w*').join(' ');
      final rows = await db.rawQuery(
        'SELECT * FROM $_tableName WHERE $_tableName MATCH ?',
        [matchQuery],
      );
      return rows.map(Screenshot.fromMap).toList();
    } on DatabaseException catch (e) {
      throw Exception('FTS4 search failed: ${e.toString()}');
    }
  }

  Future<List<Screenshot>> getAllScreenshots() async {
    if (kIsWeb) {
      // Sort descending by timestamp
      final list = List<Screenshot>.from(_webMockDb);
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }
    final db = await database;
    try {
      final rows = await db.rawQuery(
        'SELECT * FROM $_tableName ORDER BY timestamp DESC',
      );
      return rows.map(Screenshot.fromMap).toList();
    } on DatabaseException catch (e) {
      throw Exception('DB fetch failed: ${e.toString()}');
    }
  }

  Future<Screenshot?> getById(String id) async {
    if (kIsWeb) {
      try {
        return _webMockDb.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    try {
      final rows = await db.rawQuery(
        'SELECT * FROM $_tableName WHERE id MATCH ?',
        [id],
      );
      if (rows.isEmpty) return null;
      return Screenshot.fromMap(rows.first);
    } on DatabaseException catch (e) {
      throw Exception('DB getById failed: ${e.toString()}');
    }
  }

  Future<void> deleteScreenshot(String id) async {
    if (kIsWeb) {
      _webMockDb.removeWhere((Screenshot s) => s.id == id);
      _webMockAlbumScreenshots.removeWhere((r) => r['screenshot_id'] == id);
      return;
    }
    final Database db = await database;
    try {
      await db.delete(_tableName, where: 'id = ?', whereArgs: <String>[id]);
      await db.delete('album_screenshots', where: 'screenshot_id = ?', whereArgs: <String>[id]);
    } on DatabaseException catch (e) {
      throw Exception('DB delete failed: ${e.toString()}');
    }
  }

  Future<void> createAlbum(Album album) async {
    if (kIsWeb) {
      if (_webMockAlbums.any((a) => a.name.toLowerCase() == album.name.toLowerCase())) {
        throw Exception('Album already exists');
      }
      _webMockAlbums.add(album);
      return;
    }
    final db = await database;
    try {
      await db.insert('albums', album.toMap());
    } on DatabaseException catch (e) {
      throw Exception('DB createAlbum failed: ${e.toString()}');
    }
  }

  Future<void> deleteAlbum(String id) async {
    if (kIsWeb) {
      _webMockAlbums.removeWhere((a) => a.id == id);
      _webMockAlbumScreenshots.removeWhere((r) => r['album_id'] == id);
      return;
    }
    final db = await database;
    try {
      await db.delete('albums', where: 'id = ?', whereArgs: [id]);
      await db.delete('album_screenshots', where: 'album_id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      throw Exception('DB deleteAlbum failed: ${e.toString()}');
    }
  }

  Future<void> addScreenshotToAlbum(String albumId, String screenshotId) async {
    if (kIsWeb) {
      final exists = _webMockAlbumScreenshots.any(
        (r) => r['album_id'] == albumId && r['screenshot_id'] == screenshotId,
      );
      if (!exists) {
        _webMockAlbumScreenshots.add({
          'album_id': albumId,
          'screenshot_id': screenshotId,
        });
      }
      return;
    }
    final db = await database;
    try {
      await db.insert(
        'album_screenshots',
        {'album_id': albumId, 'screenshot_id': screenshotId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } on DatabaseException catch (e) {
      throw Exception('DB addScreenshotToAlbum failed: ${e.toString()}');
    }
  }

  Future<void> removeScreenshotFromAlbum(String albumId, String screenshotId) async {
    if (kIsWeb) {
      _webMockAlbumScreenshots.removeWhere(
        (r) => r['album_id'] == albumId && r['screenshot_id'] == screenshotId,
      );
      return;
    }
    final db = await database;
    try {
      await db.delete(
        'album_screenshots',
        where: 'album_id = ? AND screenshot_id = ?',
        whereArgs: [albumId, screenshotId],
      );
    } on DatabaseException catch (e) {
      throw Exception('DB removeScreenshotFromAlbum failed: ${e.toString()}');
    }
  }

  Future<List<Screenshot>> getScreenshotsForAlbum(String albumId) async {
    if (kIsWeb) {
      final ids = _webMockAlbumScreenshots
          .where((r) => r['album_id'] == albumId)
          .map((r) => r['screenshot_id'])
          .toSet();
      return _webMockDb.where((s) => ids.contains(s.id)).toList();
    }
    final db = await database;
    try {
      final rows = await db.rawQuery('''
        SELECT s.* FROM $_tableName s
        INNER JOIN album_screenshots a ON s.id = a.screenshot_id
        WHERE a.album_id = ?
        ORDER BY s.timestamp DESC
      ''', [albumId]);
      return rows.map(Screenshot.fromMap).toList();
    } on DatabaseException catch (e) {
      throw Exception('DB getScreenshotsForAlbum failed: ${e.toString()}');
    }
  }

  Future<List<Album>> getAllAlbums() async {
    if (kIsWeb) {
      return List<Album>.from(_webMockAlbums);
    }
    final db = await database;
    try {
      final rows = await db.query('albums', orderBy: 'createdAt DESC');
      return rows.map(Album.fromMap).toList();
    } on DatabaseException catch (e) {
      throw Exception('DB getAllAlbums failed: ${e.toString()}');
    }
  }
}
