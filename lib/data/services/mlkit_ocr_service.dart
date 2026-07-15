import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../domain/models/ocr_text_block.dart';
import '../../domain/repositories/ocr_service.dart';

class MlKitOcrService implements OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  @override
  Future<List<OcrTextBlock>> recognizeText(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

    final List<OcrTextBlock> blocks = <OcrTextBlock>[];

    for (final TextBlock block in recognizedText.blocks) {
      final List<OcrLine> lines = <OcrLine>[];

      for (final TextLine line in block.lines) {
        final List<OcrElement> elements = <OcrElement>[];

        for (final TextElement element in line.elements) {
          elements.add(OcrElement(
            text: element.text,
            boundingBox: element.boundingBox,
          ));
        }

        lines.add(OcrLine(
          text: line.text,
          boundingBox: line.boundingBox,
          elements: elements,
        ));
      }

      blocks.add(OcrTextBlock(
        text: block.text,
        boundingBox: block.boundingBox,
        lines: lines,
      ));
    }

    return blocks;
  }

  void dispose() {
    _recognizer.close();
  }
}
