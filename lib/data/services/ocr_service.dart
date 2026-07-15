// lib/data/services/ocr_service.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'image_resizer.dart';
import 'ocr_result.dart';

class OcrService {
  static const int _maxLongSide = 1024;

  Future<String> extractText(String filePath) async {
    // ML Kit is Android/iOS only. On desktop and Web, return a stub.
    if (kIsWeb) {
      return '[Web demo] ${p.basename(filePath)} — OCR not supported on Web';
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return '[Windows demo] ${p.basename(filePath)} — OCR not supported on desktop';
    }

    final TextRecognizer recognizer = TextRecognizer();
    try {
      final String resizedPath = await _resizeImage(filePath);
      final InputImage inputImage =
          InputImage.fromFilePath(resizedPath);
      final RecognizedText recognizedText =
          await recognizer.processImage(inputImage);
      return recognizedText.text;
    } on FileSystemException catch (e) {
      throw Exception('File error during OCR: ${e.message}');
    } on Exception catch (e) {
      throw Exception('OCR failed: ${e.toString()}');
    } finally {
      await recognizer.close();
    }
  }

  Future<String> _resizeImage(String sourcePath) async {
    if (kIsWeb) {
      throw UnsupportedError('Filesystem operations not supported on web.');
    }
    final File source = File(sourcePath);
    final Uint8List bytes = await source.readAsBytes();
    final img.Image? original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception('Could not decode image at $sourcePath');
    }

    final img.Image resized = _scaleToMax(original, _maxLongSide);

    final Directory tmp = await getTemporaryDirectory();
    final String outPath = p.join(
      tmp.path,
      'ocr_resized_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final File outFile = File(outPath);
    await outFile.writeAsBytes(img.encodeJpg(resized));
    return outPath;
  }

  img.Image _scaleToMax(img.Image src, int maxSide) {
    final int w = src.width;
    final int h = src.height;
    final int longest = w > h ? w : h;
    if (longest <= maxSide) return src;
    final double scale = maxSide / longest;
    return img.copyResize(
      src,
      width: (w * scale).round(),
      height: (h * scale).round(),
    );
  }

  Future<OcrResult> processImageDetailed(
    String filePath, {
    TextRecognitionScript script = TextRecognitionScript.latin,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('OCR not supported on Web');
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      throw UnsupportedError('OCR not supported on desktop');
    }

    final Directory tmp = await getTemporaryDirectory();
    final ResizeOutput resized = await compute(
      resizeImageIsolate,
      ResizeInput(
        sourcePath: filePath,
        tempDir: tmp.path,
        maxSide: _maxLongSide,
      ),
    );

    final TextRecognizer recognizer = TextRecognizer(script: script);
    try {
      final InputImage inputImage = InputImage.fromFilePath(resized.outputPath);
      final RecognizedText recognizedText =
          await recognizer.processImage(inputImage);

      final List<ExtractedTextBlock> blocks = <ExtractedTextBlock>[];
      for (final TextBlock block in recognizedText.blocks) {
        for (final TextLine line in block.lines) {
          final double conf = line.confidence ?? 1.0;
          final String lang = line.recognizedLanguages.isNotEmpty
              ? line.recognizedLanguages.first
              : 'en';
          blocks.add(ExtractedTextBlock(
            text: line.text,
            boundingBox: line.boundingBox,
            confidence: conf,
            language: lang,
          ));
        }
      }

      return OcrResult(
        recognizedText: recognizedText,
        blocks: blocks,
        imageWidth: resized.width,
        imageHeight: resized.height,
      );
    } on FileSystemException catch (e) {
      throw Exception('File error during OCR: ${e.message}');
    } on Exception catch (e) {
      throw Exception('OCR failed: ${e.toString()}');
    } finally {
      await recognizer.close();
      try {
        await File(resized.outputPath).delete();
      } on FileSystemException catch (_) {}
    }
  }
}
