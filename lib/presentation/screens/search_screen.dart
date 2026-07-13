// lib/presentation/screens/search_screen.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../providers/screenshot_provider.dart';
import 'screenshot_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    // Clear search state so it's fresh next time
    Future.microtask(() {
      if (mounted) {
        context.read<ScreenshotProvider>().clearSearch();
      }
    });
    super.dispose();
  }

  void _onQueryChanged(String query, ScreenshotProvider prov) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      prov.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ScreenshotProvider prov = context.watch<ScreenshotProvider>();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search screenshots…',
            border: InputBorder.none,
          ),
          onChanged: (String q) => _onQueryChanged(q, prov),
        ),
      ),
      body: Builder(
        builder: (BuildContext ctx) {
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
          if (prov.searchResults.isEmpty) {
            return const Center(
              child: Text('No results.'),
            );
          }
          return ListView.builder(
            itemCount: prov.searchResults.length,
            itemBuilder: (BuildContext ctx2, int i) {
              final s = prov.searchResults[i];
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
    );
  }
}
