// lib/presentation/screens/duplicates_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/screenshot_model.dart';
import '../providers/screenshot_provider.dart';

class DuplicatesScreen extends StatelessWidget {
  const DuplicatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScreenshotProvider provider =
        context.watch<ScreenshotProvider>();
    final List<List<Screenshot>> groups =
        provider.findDuplicateGroups();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Duplicates'),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text(
                'No duplicates found.',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (BuildContext ctx, int i) {
                return _DuplicateGroupCard(
                  group: groups[i],
                );
              },
            ),
    );
  }
}

class _DuplicateGroupCard extends StatelessWidget {
  final List<Screenshot> group;
  const _DuplicateGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.length} similar screenshots',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: group.length,
                separatorBuilder: (BuildContext _, int _) =>
                    const SizedBox(width: 8),
                itemBuilder: (BuildContext ctx, int j) {
                  final Screenshot s = group[j];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: (s.filePath.isNotEmpty && !kIsWeb)
                          ? Image.file(
                              File(s.filePath),
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
                                  const Icon(Icons.image),
                            )
                          : const Icon(Icons.image),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _keepFirst(context),
                  icon: const Icon(Icons.check,
                      color: Colors.green, size: 18),
                  label: const Text('Keep First',
                      style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _keepFirst(BuildContext context) async {
    final ScreenshotProvider provider =
        context.read<ScreenshotProvider>();
    // Delete all except the first
    for (int i = 1; i < group.length; i++) {
      await provider.deleteScreenshot(group[i].id);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Deleted ${group.length - 1} duplicate(s)'),
        ),
      );
    }
  }
}
