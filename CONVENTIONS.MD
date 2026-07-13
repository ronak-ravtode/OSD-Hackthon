# SnapSearch — Code Conventions

## Naming
| Element            | Convention     | Example                    |
|--------------------|----------------|----------------------------|
| Variables          | camelCase      | `extractedText`            |
| Functions/Methods  | camelCase      | `processImage()`           |
| Classes            | PascalCase     | `OcrService`               |
| Enums              | PascalCase     | `ImageFormat`              |
| Enum values        | camelCase      | `ImageFormat.png`          |
| Constants          | camelCase      | `maxImageWidth`            |
| File names         | snake_case     | `database_helper.dart`     |
| Database tables    | snake_case     | `screenshots`              |
| Column names       | snake_case     | `created_at`               |

## Async/Await
- **Always** use `async/await`. Never use `.then()` chains.
- Mark functions returning `Future<T>` with `async`.
- Always handle errors with `try/catch` using typed exceptions.

```dart
// ✅ Correct
Future<OcrResult> extractText(String imagePath) async {
  try {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return OcrResult(text: recognizedText.text);
  } on MLKitException catch (e) {
    throw OcrException('Text recognition failed: ${e.message}');
  }
}

// ❌ Wrong
Future<OcrResult> extractText(String imagePath) {
  return _textRecognizer.processImage(inputImage).then((result) {
    return OcrResult(text: result.text);
  });
}
```

## Error Handling
- Define custom exception classes in `lib/core/exceptions/`.
- Never use bare `catch (e)`. Always specify `on ExceptionType`.
- Propagate domain-specific exceptions, not raw `Exception`.

```dart
// ✅ Correct
on DatabaseException catch (e) {
  throw SearchException('FTS5 query failed: ${e.message}');
}

// ❌ Wrong
catch (e) {
  print(e);
}
```

## Imports
Order imports in this exact sequence, separated by blank lines:
1. `dart:` imports
2. `package:flutter/` imports
3. `package:` imports (third-party)
4. Relative `./` imports

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sqflite/sqflite.dart';

import '../models/screenshot.dart';
import '../db/database_helper.dart';
```

## Formatting
- Use single quotes for all strings: `'text'`, not `"text"`.
- Prefer `const` constructors everywhere the compiler allows.
- Prefer `final` for local variables that are never reassigned.
- Max line length: 80 characters.
- Trailing commas on the last parameter in multi-line widget/function calls.
