// lib/presentation/screens/dashboard_screen.dart

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../providers/screenshot_provider.dart';
import 'screenshot_detail_screen.dart';
import 'search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScreenshotProvider>().loadAll();
    });
  }

  Future<void> _pickAndIndex(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;
    if (!context.mounted) return;
    final provider = context.read<ScreenshotProvider>();
    for (final file in result.files) {
      final String? path = kIsWeb ? file.name : file.path;
      if (path != null) {
        await provider.indexScreenshot(path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapSearch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Index image',
            onPressed: () => _pickAndIndex(context),
          ),
        ],
      ),
      body: Consumer<ScreenshotProvider>(
        builder: (BuildContext ctx, ScreenshotProvider prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  prov.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (prov.screenshots.isEmpty) {
            return const Center(
              child: Text('No screenshots indexed yet.\nTap + to add one.'),
            );
          }
          return ListView.builder(
            itemCount: prov.screenshots.length,
            itemBuilder: (BuildContext ctx2, int i) {
              final s = prov.screenshots[i];
              final String name = p.basename(s.filePath);
              final String preview = s.extractedText.length > 80
                  ? '${s.extractedText.substring(0, 80)}…'
                  : s.extractedText;
              return ListTile(
                leading: (s.filePath.isNotEmpty && !kIsWeb)
                    ? Image.file(
                        File(s.filePath),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image_not_supported),
                      )
                    : const Icon(Icons.image),
                 title: Text(name),
                subtitle: Text(
                  preview.isEmpty ? '(no text extracted)' : preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ScreenshotDetailScreen(screenshot: s),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SearchScreen(),
          ),
        ),
        tooltip: 'Search',
        child: const Icon(Icons.search),
      ),
    );
  }
}
