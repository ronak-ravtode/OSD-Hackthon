# Skill: Build Feature

> SOP for creating a new UI feature in SnapSearch, following Model → Provider → UI.

## Prerequisites
- Read `ARCHITECTURE.md` for folder structure.
- Read `CONVENTIONS.md` for naming and code style.

## Steps

### 1. Define the Data Model
Create `lib/data/models/<feature>.dart`.

```dart
class SearchResult {
  final int id;
  final String text;
  final String sourcePath;
  final DateTime createdAt;

  const SearchResult({
    required this.id,
    required this.text,
    required this.sourcePath,
    required this.createdAt,
  });

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      id: map['id'] as int,
      text: map['text'] as String,
      sourcePath: map['source_path'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'source_path': sourcePath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
```

### 2. Create the Provider
Create `lib/features/<feature>/providers/<feature>_provider.dart`.

- Extend `ChangeNotifier`.
- Inject dependencies via constructor (database helper, services).
- Expose state as private fields with public getters.
- Call `notifyListeners()` after every state mutation.
- Never put async logic in the UI — all async work belongs here.

```dart
class SearchProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  List<SearchResult> _results = [];
  bool _isLoading = false;

  List<SearchResult> get results => _results;
  bool get isLoading => _isLoading;

  SearchProvider(this._db);

  Future<void> search(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      _results = await _db.searchFTS5(query);
    } on DatabaseException catch (e) {
      throw SearchException('Search failed: ${e.message}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 3. Build the UI
Create `lib/features/<feature>/screens/<feature>_screen.dart`.

- Use `Consumer<FeatureProvider>` or `context.watch<T>()` for reactive state.
- Keep the widget tree shallow. Extract sub-widgets into `lib/features/<feature>/widgets/`.
- Use `const` constructors wherever possible.
- Never perform business logic inside `build()`.
- Use trailing commas for multi-line widget parameters.

### 4. Register the Provider
In `main.dart` or the parent screen, wrap with `ChangeNotifierProvider`:

```dart
ChangeNotifierProvider(
  create: (_) => SearchProvider(DatabaseHelper.instance),
  child: const SearchScreen(),
),
```

### 5. Verify
- Run `flutter analyze` — zero issues.
- Run `flutter test` — all tests pass.
- Manually test the feature on emulator/device.
