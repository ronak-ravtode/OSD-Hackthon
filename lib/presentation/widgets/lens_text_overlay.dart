import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/ocr_block.dart';

/// Google Lens-style text selection with zoom/pan.
/// Drop this into your DetailScreen where the image was.
class LensTextOverlay extends StatefulWidget {
  final ImageProvider imageProvider;
  final int originalWidth;
  final int originalHeight;
  final List<OcrBlock> blocks;

  const LensTextOverlay({
    super.key,
    required this.imageProvider,
    required this.originalWidth,
    required this.originalHeight,
    required this.blocks,
  });

  @override
  State<LensTextOverlay> createState() => _LensTextOverlayState();
}

class _LensTextOverlayState extends State<LensTextOverlay> {
  final Set<int> _selected = {};
  final TransformationController _transform = TransformationController();

  bool get _hasSelection => _selected.isNotEmpty;
  String get _selectedText {
    final ordered = _selected.toList()..sort();
    return ordered.map((i) => widget.blocks[i].text).join(' ');
  }

  // ── Actions ──
  void _copy() {
    if (_selectedText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _selectedText));
    _toast('Copied');
    _clear();
  }

  void _selectAll() {
    setState(() {
      _selected.addAll(List.generate(widget.blocks.length, (i) => i));
    });
  }

  void _webSearch() async {
    if (_selectedText.isEmpty) return;
    final textToSearch = Uri.encodeComponent(_selectedText);
    await Clipboard.setData(ClipboardData(text: textToSearch));
    _toast('Copied query for manual search');
    _clear();
  }

  void _share() async {
    await Clipboard.setData(ClipboardData(text: _selectedText));
    _toast('Copied for sharing');
    _clear();
  }

  void _clear() => setState(() => _selected.clear());

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  // ── Selection logic ──
  void _toggleBlock(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Zoomable image + text blocks ──
          InteractiveViewer(
            transformationController: _transform,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 5.0,
            child: SizedBox(
              width: widget.originalWidth.toDouble(),
              height: widget.originalHeight.toDouble(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base image
                  Image(
                    image: widget.imageProvider,
                    fit: BoxFit.fill,
                  ),

                  // OCR blocks
                  ...List.generate(widget.blocks.length, (index) {
                    final block = widget.blocks[index];
                    final isSelected = _selected.contains(index);

                    return Positioned(
                      left: block.boundingBox.left,
                      top: block.boundingBox.top,
                      width: block.boundingBox.width,
                      height: block.boundingBox.height,
                      child: GestureDetector(
                        // CRITICAL: This makes the invisible box tappable
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toggleBlock(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withValues(alpha: 0.35)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.white.withValues(alpha: 0.0),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Top bar ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  if (_hasSelection)
                    CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _clear,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Bottom action bar (Google Lens style) ──
          if (_hasSelection)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: _ActionBar(
                onCopy: _copy,
                onSelectAll: _selected.length < widget.blocks.length ? _selectAll : null,
                onWebSearch: _webSearch,
                onShare: _share,
                onClear: _clear,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom Action Bar ──
class _ActionBar extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback? onSelectAll;
  final VoidCallback onWebSearch;
  final VoidCallback onShare;
  final VoidCallback onClear;

  const _ActionBar({
    required this.onCopy,
    this.onSelectAll,
    required this.onWebSearch,
    required this.onShare,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(icon: Icons.copy, label: 'Copy', onTap: onCopy),
          if (onSelectAll != null)
            _ActionButton(icon: Icons.select_all, label: 'All', onTap: onSelectAll!),
          _ActionButton(icon: Icons.search, label: 'Search', onTap: onWebSearch),
          _ActionButton(icon: Icons.share, label: 'Share', onTap: onShare),
          _ActionButton(icon: Icons.close, label: 'Close', onTap: onClear),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
