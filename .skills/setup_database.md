# Skill: Setup Database

> SOP for SQLite FTS5 setup and schema migrations in SnapSearch.

## Prerequisites
- Read `ARCHITECTURE.md` for data flow.
- Read `CONVENTIONS.md` for naming conventions (snake_case tables/columns).

## Steps

### 1. Create Database Helper
Create `lib/data/db/database_helper.dart`.

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _instance;
  static const _dbName = 'snapsearch.db';
  static const _dbVersion = 1;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<Database> get database async {
    return _instance ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
```

### 2. Define Schema with FTS5
In the `_onCreate` callback, create both the content table and the FTS5 virtual table:

```dart
Future<void> _onCreate(Database db, int version) async {
  // Content table — stores the actual data
  await db.execute('''
    CREATE TABLE screenshots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      text TEXT NOT NULL,
      source_path TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');

  // FTS5 virtual table — mirrors text column for full-text search
  await db.execute('''
    CREATE VIRTUAL TABLE screenshots_fts USING fts5(
      text,
      content='screenshots',
      content_rowid='id'
    )
  ''');

  // Triggers to keep FTS index in sync with content table
  await db.execute('''
    CREATE TRIGGER screenshots_ai AFTER INSERT ON screenshots BEGIN
      INSERT INTO screenshots_fts(rowid, text) VALUES (new.id, new.text);
    END
  ''');

  await db.execute('''
    CREATE TRIGGER screenshots_ad AFTER DELETE ON screenshots BEGIN
      INSERT INTO screenshots_fts(screenshots_fts, rowid, text) VALUES('delete', old.id, old.text);
    END
  ''');

  await db.execute('''
    CREATE TRIGGER screenshots_au AFTER UPDATE ON screenshots BEGIN
      INSERT INTO screenshots_fts(screenshots_fts, rowid, text) VALUES('delete', old.id, old.text);
      INSERT INTO screenshots_fts(rowid, text) VALUES (new.id, new.text);
    END
  ''');
}
```

### 3. Implement FTS5 Search Query
```dart
Future<List<Map<String, dynamic>>> searchFTS5(String query) async {
  final db = await database;
  return await db.rawQuery('''
    SELECT s.id, s.text, s.source_path, s.created_at
    FROM screenshots s
    INNER JOIN screenshots_fts fts ON s.id = fts.rowid
    WHERE screenshots_fts MATCH ?
    ORDER BY rank
  ''', [query]);
}
```

### 4. Implement Insert with FTS Sync
```dart
Future<int> insertScreenshot(String text, String sourcePath) async {
  final db = await database;
  return await db.insert('screenshots', {
    'text': text,
    'source_path': sourcePath,
    'created_at': DateTime.now().millisecondsSinceEpoch,
  });
}
```

### 5. Migrations
When incrementing `_dbVersion`, add logic in `onUpgrade`:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE screenshots ADD COLUMN tags TEXT DEFAULT ""');
  }
}
```

- **Never drop tables** in production migrations. Only add columns or create new tables.
- Test every migration path: fresh install, upgrade from N-1, upgrade from N-2.

### 6. Verify
- Run `flutter analyze` — zero issues.
- Write a unit test that creates an in-memory database, inserts rows, and verifies FTS5 search returns correct results.
