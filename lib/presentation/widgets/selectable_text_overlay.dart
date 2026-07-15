import 'dart:math';
import 'package:flutter/material.dart' hide TextSelectionToolbar;
import 'package:flutter/services.dart';
import '../../domain/models/ocr_block.dart';
import 'text_selection_toolbar.dart';

/// Google Photos-style text selection overlay.
/// Drop this on top of your image in DetailScreen.
class SelectableTextOverlay extends StatefulWidget {
  final ImageProvider imageProvider;
  final int originalImageWidth;
  final int originalImageHeight;
  final List<OcrBlock> blocks;
  final VoidCallback? onSelectionChanged;

  const SelectableTextOverlay({
    super.key,
    required this.imageProvider,
    required this.originalImageWidth,
    required this.originalImageHeight,
    required this.blocks,
    this.onSelectionChanged,
  });

  @override
  State<SelectableTextOverlay> createState() => _SelectableTextOverlayState();
}

class _SelectableTextOverlayState extends State<SelectableTextOverlay> {
  final Set<int> _selectedIndices = {};
  bool _showToolbar = false;
  Offset? _toolbarPosition;

  List<OcrBlock> get _selectedBlocks => _selectedIndices
      .map((i) => widget.blocks[i])
      .toList();

  String get _selectedText => _selectedBlocks.map((b) => b.text).join(' ');

  void _toggleSelection(int index, Offset globalPosition) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
      _showToolbar = _selectedIndices.isNotEmpty;
      _toolbarPosition = globalPosition;
    });
    widget.onSelectionChanged?.call();
  }

  void _selectAll() {
    setState(() {
      _selectedIndices.addAll(
        List.generate(widget.blocks.length, (i) => i),
      );
      _showToolbar = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
      _showToolbar = false;
      _toolbarPosition = null;
    });
  }

  Future<void> _copySelected() async {
    if (_selectedText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _selectedText));
    _showSnack('Copied to clipboard');
    _clearSelection();
  }

  Future<void> _webSearch() async {
    if (_selectedText.isEmpty) return;
    final textToSearch = Uri.encodeComponent(_selectedText);
    await Clipboard.setData(ClipboardData(text: textToSearch));
    _showSnack('Copied query for manual search');
  }

  Future<void> _shareText() async {
    await Clipboard.setData(ClipboardData(text: _selectedText));
    _showSnack('Text copied for sharing');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: If original dimensions are invalid, fallback to raw image
    if (widget.originalImageWidth <= 0 || widget.originalImageHeight <= 0) {
      return Image(image: widget.imageProvider, fit: BoxFit.contain);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final displayedWidth = constraints.maxWidth;
        final displayedHeight = constraints.maxHeight;

        // Calculate scale factors
        final scaleX = displayedWidth / widget.originalImageWidth;
        final scaleY = displayedHeight / widget.originalImageHeight;

        // Use uniform scale to avoid distortion, like Google Photos
        final scale = min(scaleX, scaleY);

        // Center the image if letterboxed
        final offsetX = (displayedWidth - widget.originalImageWidth * scale) / 2;
        final offsetY = (displayedHeight - widget.originalImageHeight * scale) / 2;

        return GestureDetector(
          // CRITICAL FIX: This allows taps to pass through to children
          // while still catching the background tap to clear selection
          behavior: HitTestBehavior.translucent,
          onTap: _clearSelection,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base image
              Image(
                image: widget.imageProvider,
                fit: BoxFit.contain,
                width: displayedWidth,
                height: displayedHeight,
              ),

              // Text blocks
              ...List.generate(widget.blocks.length, (index) {
                final block = widget.blocks[index];
                final isSelected = _selectedIndices.contains(index);

                // Scale coordinates
                final left = block.boundingBox.left * scale + offsetX;
                final top = block.boundingBox.top * scale + offsetY;
                final width = block.boundingBox.width * scale;
                final height = block.boundingBox.height * scale;

                return Positioned(
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: GestureDetector(
                    // CRITICAL FIX: Opaque ensures this receives touches
                    // even if the child is transparent
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // Stop propagation so background clear doesn't fire
                      _toggleSelection(index, Offset(left + width / 2, top));
                    },
                    onLongPress: () {
                      if (_selectedIndices.isEmpty) {
                        _selectAll();
                      } else {
                        _copySelected();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.white.withValues(alpha: 0.0),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSelected
                          ? const SizedBox.shrink()
                          : null,
                    ),
                  ),
                );
              }),

              // Floating toolbar
              if (_showToolbar && _toolbarPosition != null)
                Positioned(
                  left: max(8, min(
                    _toolbarPosition!.dx - 100,
                    displayedWidth - 208,
                  )),
                  top: max(8, _toolbarPosition!.dy - 60),
                  child: TextSelectionToolbar(
                    onCopy: _copySelected,
                    onSelectAll: _selectedIndices.length < widget.blocks.length
                        ? _selectAll
                        : null,
                    onWebSearch: _webSearch,
                    onShare: _shareText,
                    onDismiss: _clearSelection,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
