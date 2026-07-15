import 'dart:io';
import '../../domain/models/ocr_text_block.dart';

abstract class OcrService {
  Future<List<OcrTextBlock>> recognizeText(File imageFile);
}
