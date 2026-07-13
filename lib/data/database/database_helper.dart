// lib/data/database/database_helper.dart

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/screenshot_model.dart';

class DatabaseHelper {
  static const String _dbName = 'snap_search_v2.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'screenshots';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;
  
  // In-memory fallback database for Web
  final List<Screenshot> _webMockDb = [];

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
}
