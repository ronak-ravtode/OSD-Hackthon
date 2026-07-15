import 'package:flutter/material.dart';
import '../../domain/models/ocr_text_block.dart';
import 'coordinate_translator.dart';

class OcrOverlayPainter extends CustomPainter {
  final List<OcrTextBlock> blocks;
  final Size imageSize;
  final BoxFit fit;
  final Color boxColor;
  final Color textColor;

  const OcrOverlayPainter({
    required this.blocks,
    required this.imageSize,
    this.fit = BoxFit.contain,
    this.boxColor = Colors.blue,
    this.textColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = boxColor;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = boxColor.withValues(alpha: 0.15);

    for (final OcrTextBlock block in blocks) {
      final Rect scaledRect = CoordinateTranslator.translateRect(
        rect: block.boundingBox,
        imageSize: imageSize,
        canvasSize: size,
        fit: fit,
      );

      canvas.drawRect(scaledRect, fillPaint);
      canvas.drawRect(scaledRect, borderPaint);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: block.text,
          style: TextStyle(
            color: textColor,
            fontSize: 10.0,
            backgroundColor: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: scaledRect.width);

      textPainter.paint(
        canvas,
        Offset(scaledRect.left, scaledRect.top - textPainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OcrOverlayPainter oldDelegate) {
    return oldDelegate.blocks != blocks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.fit != fit ||
        oldDelegate.boxColor != boxColor ||
        oldDelegate.textColor != textColor;
  }
}
