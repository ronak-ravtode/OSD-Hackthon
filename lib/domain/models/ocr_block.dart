import 'dart:ui';

class OcrBlock {
  final String text;
  final Rect boundingBox; // Original image coordinates
  final double confidence;

  const OcrBlock({
    required this.text,
    required this.boundingBox,
    this.confidence = 1.0,
  });

  factory OcrBlock.fromMlKit(Map<String, dynamic> json) {
    final rect = json['rect'] as Map<String, dynamic>;
    return OcrBlock(
      text: json['text'] as String,
      boundingBox: Rect.fromLTRB(
        (rect['left'] as num).toDouble(),
        (rect['top'] as num).toDouble(),
        (rect['right'] as num).toDouble(),
        (rect['bottom'] as num).toDouble(),
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
