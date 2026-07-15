import 'package:flutter/material.dart';

class TextSelectionToolbar extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback? onSelectAll;
  final VoidCallback onWebSearch;
  final VoidCallback onShare;
  final VoidCallback onDismiss;

  const TextSelectionToolbar({
    super.key,
    required this.onCopy,
    this.onSelectAll,
    required this.onWebSearch,
    required this.onShare,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.grey.shade900,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarButton(
              icon: Icons.copy,
              label: 'Copy',
              onTap: onCopy,
            ),
            if (onSelectAll != null)
              _ToolbarButton(
                icon: Icons.select_all,
                label: 'All',
                onTap: onSelectAll!,
              ),
            _ToolbarButton(
              icon: Icons.search,
              label: 'Search',
              onTap: onWebSearch,
            ),
            _ToolbarButton(
              icon: Icons.share,
              label: 'Share',
              onTap: onShare,
            ),
            _ToolbarButton(
              icon: Icons.close,
              label: 'Close',
              onTap: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
