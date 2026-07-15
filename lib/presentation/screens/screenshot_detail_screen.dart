// lib/presentation/screens/screenshot_detail_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../core/utils/action_extractor.dart';
import '../../core/utils/redaction_engine.dart';
import '../../core/utils/smart_tagger.dart';
import '../../core/utils/summarizer.dart';
import '../../data/services/ocr_result.dart';
import '../../data/services/ocr_service.dart';
import '../../domain/models/screenshot_model.dart';
import '../providers/screenshot_provider.dart';
import '../widgets/text_highlight_overlay.dart';

class ScreenshotDetailScreen extends StatefulWidget {
  final Screenshot screenshot;
  const ScreenshotDetailScreen({super.key, required this.screenshot});

  @override
  State<ScreenshotDetailScreen> createState() => _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState extends State<ScreenshotDetailScreen> {
  bool _showBars = true;
  bool _highlightMode = false;
  bool _loadingOcr = false;
  OcrResult? _ocrResult;
  TextRecognitionScript _selectedScript = TextRecognitionScript.latin;

  Future<void> _runOcr({TextRecognitionScript script = TextRecognitionScript.latin}) async {
    setState(() {
      _loadingOcr = true;
      _selectedScript = script;
    });
    try {
      final OcrResult res = await OcrService()
          .processImageDetailed(widget.screenshot.filePath, script: script);
      if (mounted) {
        setState(() {
          _ocrResult = res;
          _highlightMode = true;
          _loadingOcr = false;
        });
        if (res.blocks.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text detected in this image')),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loadingOcr = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load text coordinates: $e')),
        );
      }
    }
  }

  Future<void> _toggleHighlightMode() async {
    if (_highlightMode) {
      setState(() => _highlightMode = false);
      return;
    }
    if (_ocrResult != null) {
      setState(() => _highlightMode = true);
      return;
    }
    await _runOcr(script: _selectedScript);
  }

  Future<void> _selectScriptAndReRun() async {
    final TextRecognitionScript? script = await showDialog<TextRecognitionScript>(
      context: context,
      builder: (BuildContext ctx) => SimpleDialog(
        title: const Text('Select Language Model'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, TextRecognitionScript.latin),
            child: const Text('Latin (Default)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, TextRecognitionScript.chinese),
            child: const Text('Chinese'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, TextRecognitionScript.devanagiri),
            child: const Text('Devanagari'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, TextRecognitionScript.japanese),
            child: const Text('Japanese'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, TextRecognitionScript.korean),
            child: const Text('Korean'),
          ),
        ],
      ),
    );
    if (script != null && mounted) {
      await _runOcr(script: script);
    }
  }

  void _copyAllText() {
    if (_ocrResult == null || _ocrResult!.blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No extracted text available to copy')),
      );
      return;
    }
    final String allText = _ocrResult!.blocks.map((ExtractedTextBlock b) => b.text).join('\n');
    Clipboard.setData(ClipboardData(text: allText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All extracted text copied to clipboard.')),
    );
  }

  void _showSmartActions() {
    final List<ActionItem> actions =
        ActionExtractor.extract(widget.screenshot.extractedText);
    if (actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No actionable items found')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions.map((ActionItem a) {
            return ActionChip(
              avatar: Icon(a.icon, size: 18),
              label: Text('${a.label}: ${a.value.length > 25 ? '${a.value.substring(0, 25)}…' : a.value}'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: a.value));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${a.label} copied!')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPrivacyCheck() {
    final List<PiiMatch> pii =
        RedactionEngine.detect(widget.screenshot.extractedText);
    if (pii.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sensitive info detected')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Sensitive Info Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: pii.map((PiiMatch m) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(m.label),
              subtitle: Text(m.value.length > 20
                  ? '${m.value.substring(0, 20)}…'
                  : m.value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final String redacted =
                  RedactionEngine.redactText(widget.screenshot.extractedText);
              Clipboard.setData(ClipboardData(text: redacted));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redacted text copied')),
              );
            },
            child: const Text('Copy Redacted'),
          ),
        ],
      ),
    );
  }

  void _showSummary() {
    final String summary =
        TextRankSummarizer.summarize(widget.screenshot.extractedText);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Summary'),
        content: SelectableText(summary),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summary));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showTags() {
    final List<String> tags =
        SmartTagger.tag(widget.screenshot.extractedText);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Smart Tags'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((String t) {
            return Chip(label: Text(t));
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Delete this image from Trace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context
          .read<ScreenshotProvider>()
          .deleteScreenshot(widget.screenshot.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Screenshot deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String filename = p.basename(widget.screenshot.filePath);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _highlightMode ? () => FocusScope.of(context).unfocus() : () => setState(() => _showBars = !_showBars),
              child: _highlightMode
                  ? LayoutBuilder(
                      builder: (BuildContext ctx, BoxConstraints constraints) {
                        final Size cSize =
                            Size(constraints.maxWidth, constraints.maxHeight);
                        return Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: const TextSelectionThemeData(
                              selectionColor: Color(0x664285F4),
                              selectionHandleColor: Color(0xFF4285F4),
                            ),
                          ),
                          child: SelectionArea(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (widget.screenshot.filePath.isNotEmpty && !kIsWeb)
                                  Image.file(File(widget.screenshot.filePath),
                                      fit: BoxFit.contain)
                                else
                                  const Center(
                                      child: Icon(Icons.image,
                                          size: 64, color: Colors.grey)),
                                if (_ocrResult != null) ...[
                                  TextHighlightOverlay(
                                    ocr: _ocrResult!,
                                    size: cSize,
                                  ),
                                  if (_ocrResult!.blocks.isEmpty)
                                    const Center(
                                      child: Card(
                                        color: Colors.black87,
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Text(
                                            'No text detected in this image',
                                            style: TextStyle(color: Colors.white, fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                                if (_loadingOcr)
                                  const Center(child: CircularProgressIndicator()),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      clipBehavior: Clip.none,
                      child: LayoutBuilder(
                        builder: (BuildContext ctx, BoxConstraints constraints) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              if (widget.screenshot.filePath.isNotEmpty && !kIsWeb)
                                Image.file(File(widget.screenshot.filePath),
                                    fit: BoxFit.contain)
                              else
                                const Center(
                                    child: Icon(Icons.image,
                                        size: 64, color: Colors.grey)),
                              if (_loadingOcr)
                                const Center(child: CircularProgressIndicator()),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ),
          if (_showBars)
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(filename)),
          if (_showBars)
            Positioned(
                bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  Widget _buildTopBar(String name) {
    return Container(
      color: Colors.black54,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top, bottom: 8),
      child: NavigationToolbar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(name,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (String val) {
            if (val == 'copy_all') {
              _copyAllText();
            } else if (val == 're_run') {
              _selectScriptAndReRun();
            }
          },
          itemBuilder: (BuildContext _) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'info', child: Text('Info')),
            const PopupMenuItem<String>(value: 'copy_all', child: Text('Copy All Extracted Text')),
            const PopupMenuItem<String>(value: 're_run', child: Text('Re-run OCR')),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black54,
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white, size: 28),
            onPressed: _confirmDelete,
          ),
          IconButton(
            icon: Icon(
              Icons.select_all,
              color: _highlightMode ? const Color(0xFF4285F4) : Colors.white,
              size: 28,
            ),
            onPressed: _toggleHighlightMode,
          ),
          IconButton(
            icon: const Icon(Icons.bolt, color: Colors.white, size: 28),
            tooltip: 'Smart Actions',
            onPressed: _showSmartActions,
          ),
          IconButton(
            icon: const Icon(Icons.shield, color: Colors.white, size: 28),
            tooltip: 'Privacy Check',
            onPressed: _showPrivacyCheck,
          ),
          IconButton(
            icon: const Icon(Icons.summarize, color: Colors.white, size: 28),
            tooltip: 'Summary',
            onPressed: _showSummary,
          ),
          IconButton(
            icon: const Icon(Icons.label, color: Colors.white, size: 28),
            tooltip: 'Tags',
            onPressed: _showTags,
          ),
        ],
      ),
    );
  }
}
