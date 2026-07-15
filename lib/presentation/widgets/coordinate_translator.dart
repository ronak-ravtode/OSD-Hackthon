import 'package:flutter/widgets.dart';

class CoordinateTranslator {
  const CoordinateTranslator._();

  static double scale({
    required double coordinate,
    required double rawLength,
    required double canvasLength,
    required double scaleFactor,
    required double offset,
  }) {
    return coordinate * scaleFactor + offset;
  }

  static Rect translateRect({
    required Rect rect,
    required Size imageSize,
    required Size canvasSize,
    BoxFit fit = BoxFit.contain,
  }) {
    final double scaleX = canvasSize.width / imageSize.width;
    final double scaleY = canvasSize.height / imageSize.height;

    final double scaleFactor = (fit == BoxFit.contain)
        ? (scaleX < scaleY ? scaleX : scaleY)
        : (scaleX > scaleY ? scaleX : scaleY);

    final double dx = (canvasSize.width - imageSize.width * scaleFactor) / 2.0;
    final double dy = (canvasSize.height - imageSize.height * scaleFactor) / 2.0;

    return Rect.fromLTRB(
      rect.left * scaleFactor + dx,
      rect.top * scaleFactor + dy,
      rect.right * scaleFactor + dx,
      rect.bottom * scaleFactor + dy,
    );
  }
}
