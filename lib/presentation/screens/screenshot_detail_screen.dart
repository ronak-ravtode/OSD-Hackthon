// lib/presentation/screens/screenshot_detail_screen.dart

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/screenshot_model.dart';

class ScreenshotDetailScreen extends StatelessWidget {
  final Screenshot screenshot;

  const ScreenshotDetailScreen({super.key, required this.screenshot});

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: screenshot.extractedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String filename = p.basename(screenshot.filePath);
    final String dateString = screenshot.timestamp.toLocal().toString().split('.')[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(filename),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy extracted text',
            onPressed: () => _copyToClipboard(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Container
            Container(
              height: 300,
              color: Colors.black12,
              child: (screenshot.filePath.isNotEmpty && !kIsWeb)
                  ? InteractiveViewer(
                      maxScale: 4.0,
                      child: Image.file(
                        File(screenshot.filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(Icons.image_not_supported, size: 64),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
            ),
            
            // Metadata Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category: ${screenshot.category}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            dateString,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Extracted Text Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Extracted Text',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // Extracted Text Scrollable Panel
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: screenshot.extractedText.trim().isEmpty
                    ? const Text(
                        '(No text detected in this image)',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      )
                    : SelectableText(
                        screenshot.extractedText,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      ),
              ),
            ),
            const SizedBox(height: 80), // spacer for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _copyToClipboard(context),
        label: const Text('Copy Text'),
        icon: const Icon(Icons.copy),
      ),
    );
  }
}
