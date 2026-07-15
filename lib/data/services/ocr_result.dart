// lib/data/services/ocr_result.dart

import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ExtractedTextBlock {
  final String text;
  final Rect boundingBox;
  final double confidence;
  final String language;

  const ExtractedTextBlock({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    required this.language,
  });
}

class OcrResult {
  final RecognizedText recognizedText;
  final List<ExtractedTextBlock> blocks;
  final double imageWidth;
  final double imageHeight;

  const OcrResult({
    required this.recognizedText,
    required this.blocks,
    required this.imageWidth,
    required this.imageHeight,
  });
}
