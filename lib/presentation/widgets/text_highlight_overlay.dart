// lib/presentation/widgets/text_highlight_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/ocr_result.dart';

class TextHighlightOverlay extends StatelessWidget {
  final OcrResult ocr;
  final Size size;

  const TextHighlightOverlay({
    super.key,
    required this.ocr,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (ocr.imageWidth <= 0 || ocr.imageHeight <= 0) {
      return const SizedBox.shrink();
    }
    final double imgRatio = ocr.imageWidth / ocr.imageHeight;
    final double cRatio = size.width / size.height;
    final double dW =
        imgRatio > cRatio ? size.width : size.height * imgRatio;
    final double dH =
        imgRatio > cRatio ? size.width / imgRatio : size.height;
    final double dx = (size.width - dW) / 2.0;
    final double dy = (size.height - dH) / 2.0;
    final double sX = dW / ocr.imageWidth;
    final double sY = dH / ocr.imageHeight;

    return Stack(
      children: [
        for (final ExtractedTextBlock block in ocr.blocks)
          Positioned(
            left: dx + block.boundingBox.left * sX,
            top: dy + block.boundingBox.top * sY,
            width: block.boundingBox.width * sX,
            height: block.boundingBox.height * sY,
            child: _TapToCopyBlock(text: block.text),
          ),
      ],
    );
  }
}

class _TapToCopyBlock extends StatelessWidget {
  final String text;
  const _TapToCopyBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: ${text.length > 40 ? '${text.substring(0, 40)}…' : text}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x1F4285F4),
          borderRadius: BorderRadius.circular(3.0),
          border: Border.all(
            color: const Color(0x554285F4),
            width: 0.5,
          ),
        ),
      ),
    );
  }
}
