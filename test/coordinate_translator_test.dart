import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:snap_search/presentation/widgets/coordinate_translator.dart';

void main() {
  group('CoordinateTranslator tests', () {
    test('scales coordinates correctly under BoxFit.contain', () {
      const Size rawImageSize = Size(1000.0, 500.0);
      const Size canvasSize = Size(500.0, 500.0);
      const Rect rawRect = Rect.fromLTRB(100.0, 100.0, 900.0, 400.0);

      final Rect translated = CoordinateTranslator.translateRect(
        rect: rawRect,
        imageSize: rawImageSize,
        canvasSize: canvasSize,
      );

      expect(translated.left, closeTo(50.0, 0.001));
      expect(translated.top, closeTo(175.0, 0.001));
      expect(translated.right, closeTo(450.0, 0.001));
      expect(translated.bottom, closeTo(325.0, 0.001));
    });
  });
}
