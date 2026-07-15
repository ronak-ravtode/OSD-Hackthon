// lib/data/services/image_resizer.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ResizeInput {
  final String sourcePath;
  final String tempDir;
  final int maxSide;
  const ResizeInput({
    required this.sourcePath,
    required this.tempDir,
    required this.maxSide,
  });
}

class ResizeOutput {
  final String outputPath;
  final double width;
  final double height;
  const ResizeOutput({
    required this.outputPath,
    required this.width,
    required this.height,
  });
}

ResizeOutput resizeImageIsolate(ResizeInput input) {
  final File source = File(input.sourcePath);
  final Uint8List bytes = source.readAsBytesSync();
  final img.Image? original = img.decodeImage(bytes);
  if (original == null) {
    throw Exception('Could not decode image');
  }
  final int w = original.width;
  final int h = original.height;
  final int longest = w > h ? w : h;
  img.Image resized = original;
  if (longest > input.maxSide) {
    final double scale = input.maxSide / longest;
    resized = img.copyResize(
      original,
      width: (w * scale).round(),
      height: (h * scale).round(),
    );
  }
  final String outPath = '${input.tempDir}/ocr_res_${DateTime.now().millisecondsSinceEpoch}.jpg';
  File(outPath).writeAsBytesSync(img.encodeJpg(resized));
  return ResizeOutput(
    outputPath: outPath,
    width: resized.width.toDouble(),
    height: resized.height.toDouble(),
  );
}
