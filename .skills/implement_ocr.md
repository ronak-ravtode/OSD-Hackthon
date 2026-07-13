# Skill: Implement OCR

> SOP for integrating Google ML Kit text recognition and image preprocessing.

## Prerequisites
- Read `ARCHITECTURE.md` for data flow.
- Read `CONVENTIONS.md` for async/await and error handling.
- `google_mlkit_text_recognition` and `image` packages must be in `pubspec.yaml`.

## Steps

### 1. Create OCR Service
Create `lib/features/ocr/providers/ocr_service.dart`.

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer;

  OcrService()
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } on MLKitException catch (e) {
      throw OcrException('Text recognition failed: ${e.message}');
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
```

### 2. Image Preprocessing
Before feeding an image to ML Kit, preprocess it for better accuracy:

```dart
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  /// Resizes and converts image to grayscale for optimal OCR.
  static Future<String> preprocess(String inputPath, String outputPath) async {
    final bytes = await File(inputPath).readAsBytes();
    var image = img.decodeImage(bytes);

    if (image == null) {
      throw OcrException('Failed to decode image');
    }

    // Resize to max 1024px on longest side (reces memory, improves speed)
    const maxSize = 1024;
    if (image.width > maxSize || image.height > maxSize) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? maxSize : null,
        height: image.height >= image.width ? maxSize : null,
      );
    }

    // Convert to grayscale — improves OCR accuracy on colored backgrounds
    image = img.grayscale(image);

    // Encode back to PNG
    final processedBytes = img.encodePng(image);
    await File(outputPath).writeAsBytes(processedBytes);

    return outputPath;
  }
}
```

### 3. Create OCR Provider
Create `lib/features/ocr/providers/ocr_provider.dart`.

```dart
class OcrProvider extends ChangeNotifier {
  final OcrService _ocrService;
  final DatabaseHelper _db;
  bool _isProcessing = false;
  String _lastExtractedText = '';

  bool get isProcessing => _isProcessing;
  String get lastExtractedText => _lastExtractedText;

  OcrProvider(this._ocrService, this._db);

  Future<void> processImage(String imagePath) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // Step 1: Preprocess
      final tempDir = await getTemporaryDirectory();
      final preprocessedPath = join(tempDir.path, 'preprocessed.png');
      await ImagePreprocessor.preprocess(imagePath, preprocessedPath);

      // Step 2: Extract text
      _lastExtractedText = await _ocrService.extractText(preprocessedPath);

      // Step 3: Store in database
      await _db.insertScreenshot(_lastExtractedText, imagePath);
    } on OcrException catch (e) {
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
```

### 4. Permission Handling
Before accessing the photo library, request permission:

```dart
Future<bool> requestPermission() async {
  final status = await Permission.photos.request();
  if (status.isGranted) return true;

  // Fallback: try storage permission for Android < 13
  final storageStatus = await Permission.storage.request();
  return storageStatus.isGranted;
}
```

### 5. Dispose Resources
Always dispose the text recognizer when the provider is disposed:

```dart
@override
void dispose() {
  _ocrService.dispose();
  super.dispose();
}
```

### 6. Verify
- Run `flutter analyze` — zero issues.
- Test with a known image containing text → verify extracted text matches.
- Test with a blank image → verify empty string returned, no crash.
- Test permission denial → verify graceful error, no crash.
