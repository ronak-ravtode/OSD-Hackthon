import 'dart:ui';

class OcrElement {
  final String text;
  final Rect boundingBox;

  const OcrElement({
    required this.text,
    required this.boundingBox,
  });
}

class OcrLine {
  final String text;
  final Rect boundingBox;
  final List<OcrElement> elements;

  const OcrLine({
    required this.text,
    required this.boundingBox,
    required this.elements,
  });
}

class OcrTextBlock {
  final String text;
  final Rect boundingBox;
  final List<OcrLine> lines;

  const OcrTextBlock({
    required this.text,
    required this.boundingBox,
    required this.lines,
  });
}
