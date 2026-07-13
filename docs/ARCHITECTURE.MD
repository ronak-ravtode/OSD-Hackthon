# SnapSearch — Architecture

## Overview
SnapSearch is an **offline-first** mobile app that captures screenshots, extracts text via OCR, indexes it in a local SQLite FTS5 database, and provides instant full-text search — all without a network connection.

## Tech Stack
| Layer            | Technology                                      |
|------------------|--------------------------------------------------|
| Framework        | Flutter (Dart 3)                                |
| OCR Engine       | Google ML Kit — Text Recognition (`google_mlkit_text_recognition`) |
| Local Database   | SQLite via `sqflite` with **FTS5** virtual table for full-text search |
| State Management | Provider (`provider`)                           |
| Image Processing | `image` package for preprocessing before OCR    |
| Permissions      | `permission_handler` for runtime permissions    |
| File System      | `path_provider` for resolving platform directories |

## Folder Structure
```
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── exceptions/
│   ├── utils/
│   └── theme/
├── features/
│   ├── ocr/
│   │   ├── models/
│   │   ├── providers/
│   │   └── screens/
│   ├── search/
│   │   ├── models/
│   │   ├── providers/
│   │   └── screens/
│   └── ui/
│       ├── widgets/
│       └── screens/
├── data/
│   ├── db/
│   │   ├── database_helper.dart
│   │   └── migrations/
│   └── models/
│       ├── screenshot.dart
│       └── search_result.dart
```

## Data Flow
1. User grants photo/library permission via `permission_handler`.
2. User selects or captures an image.
3. `image` package preprocesses the image (resize, grayscale) for optimal OCR.
4. **OCR Provider** feeds the preprocessed image to Google ML Kit Text Recognition → extracts raw text.
5. **Database Helper** inserts extracted text + metadata (timestamp, source path) into SQLite.
   - A **FTS5 virtual table** mirrors the text column for fast full-text queries.
6. User types a search query in the **Search Provider**.
7. **Search Provider** executes an FTS5 `MATCH` query against SQLite.
8. Results flow back through Provider → UI renders the list.

## Key Design Decisions
- **FTS5 over LIKE**: FTS5 provides tokenization, ranking, and substring matching with far better performance than `LIKE '%query%'`.
- **Provider over Riverpod/Bloc**: Provider is sufficient for this scope and keeps dependencies minimal.
- **Offline-first**: No network calls ever. All data stays on-device.
- **Image preprocessing**: Converting to grayscale and resizing before OCR significantly improves accuracy and speed on mobile devices.


## 1. System Overview
SnapSearch is an offline-first Flutter mobile application that indexes device screenshots, extracts text via local OCR, and provides semantic/keyword search. 
- **NO CLOUD BACKEND**: All processing, storage, and AI inference happen on-device.
- **Privacy First**: No user data leaves the device.

## 2. Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Local Database**: SQLite (`sqflite`) with FTS5 for full-text search.
- **OCR Engine**: Google ML Kit (`google_mlkit_text_recognition`)
- **Image Processing**: `image` package (for resizing before OCR)

## 3. Clean Architecture Layers
The app is strictly divided into three layers. 

### Domain Layer (`lib/domain/`)
- **Ownership**: SHARED (Read-only for both agents).
- **Contents**: Pure Dart models, abstract repository interfaces, custom exceptions.
- **Rule**: Zero dependencies on Flutter, UI, or external packages.

### Data Layer (`lib/data/`)
- **Ownership**: TEAMMATE 1 (Data Agent).
- **Contents**: Repository implementations, SQLite database helpers, ML Kit OCR service, file system operations.
- **Rule**: Implements interfaces from the Domain layer. Never imports from Presentation.

### Presentation Layer (`lib/presentation/`)
- **Ownership**: TEAMMATE 2 (UI Agent).
- **Contents**: Widgets, Screens, Providers (State Management), Themes.
- **Rule**: Consumes Domain interfaces via Dependency Injection. Never imports from Data layer directly.

## 4. Data Flow
1. User grants permission -> UI triggers `Provider`.
2. Provider calls `IScreenshotRepository.indexScreenshot()`.
3. Data Layer reads file -> resizes image -> runs ML Kit OCR -> saves to SQLite.
4. UI queries `IScreenshotRepository.searchScreenshots()` -> SQLite FTS5 returns results -> UI renders list.