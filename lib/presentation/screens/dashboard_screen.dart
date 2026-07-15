// lib/presentation/screens/dashboard_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/screenshot_model.dart';
import '../../domain/models/album_model.dart';
import '../providers/screenshot_provider.dart';
import '../widgets/collections_tab_widget.dart';
import 'duplicates_screen.dart';
import 'screenshot_detail_screen.dart';
import 'search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0; // 0 = All Photos, 1 = Collections

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
    final ScreenshotProvider provider = context.read<ScreenshotProvider>();
    int duplicateCount = 0;
    for (final PlatformFile file in result.files) {
      final String? path = kIsWeb ? file.name : file.path;
      if (path != null) {
        final bool success = await provider.indexScreenshot(path);
        if (!success) {
          duplicateCount++;
        }
      }
    }
    if (!context.mounted) return;
    if (duplicateCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicateCount == 1
                ? '1 duplicate photo ignored.'
                : '$duplicateCount duplicate photos ignored.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Map<String, List<Screenshot>> _groupPhotosByDay(List<Screenshot> list) {
    final Map<String, List<Screenshot>> groups = <String, List<Screenshot>>{};
    for (final Screenshot s in list) {
      final DateTime date = s.timestamp;
      final String label = _getDateLabel(date);
      if (!groups.containsKey(label)) {
        groups[label] = <Screenshot>[];
      }
      groups[label]!.add(s);
    }
    return groups;
  }

  String _getDateLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime compare = DateTime(date.year, date.month, date.day);

    if (compare == today) {
      return 'Today';
    } else if (compare == yesterday) {
      return 'Yesterday';
    } else {
      final List<String> months = <String>[
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  void _showAddToAlbumDialog(BuildContext context, Set<String> selectedIds) {
    final ScreenshotProvider provider = context.read<ScreenshotProvider>();
    final TextEditingController newAlbumController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext c, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Add to Album'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (provider.albums.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No custom albums created yet.', style: TextStyle(color: Colors.white54)),
                      )
                    else
                      ...provider.albums.map((Album album) {
                        return ListTile(
                          title: Text(album.name),
                          onTap: () async {
                            await provider.addMultipleScreenshotsToAlbum(album.id, selectedIds.toList());
                            if (ctx.mounted) Navigator.pop(ctx);
                            provider.clearSelection();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to ${album.name}')),
                              );
                            }
                          },
                        );
                      }),
                    const Divider(color: Colors.white24),
                    const Text('Create New Album', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newAlbumController,
                      decoration: const InputDecoration(
                        hintText: 'Album name',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final String name = newAlbumController.text.trim();
                        if (name.isNotEmpty) {
                          await provider.createAlbum(name);
                          final Album newAlbum = provider.albums.firstWhere(
                            (Album a) => a.name == name,
                            orElse: () => provider.albums.first,
                          );
                          await provider.addMultipleScreenshotsToAlbum(
                            newAlbum.id,
                            selectedIds.toList(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          provider.clearSelection();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Created & added to $name')),
                            );
                          }
                        }
                      },
                      child: const Text('Create & Add'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScreenshotProvider provider = context.watch<ScreenshotProvider>();
    final bool isSel = provider.isSelectionMode;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: isSel
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => provider.clearSelection(),
              )
            : null,
        title: isSel
            ? Text(
                '${provider.selectedIds.length} item${provider.selectedIds.length == 1 ? "" : "s"} selected',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              )
            : const Text('Trace'),
        actions: isSel
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all, color: Colors.white),
                  onPressed: () {
                    final List<String> allIds = provider.screenshots.map((Screenshot s) => s.id).toList();
                    provider.selectAll(allIds);
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SearchScreen(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.radar, color: Colors.white),
                  tooltip: 'Scan for new screenshots',
                  onPressed: () async {
                    final int count = await provider.scanForNewScreenshots();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(count > 0
                            ? 'Indexed $count new screenshot${count == 1 ? '' : 's'}'
                            : 'No new screenshots found'),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  onPressed: () => _pickAndIndex(context),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (String val) {
                    if (val == 'duplicates') {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DuplicatesScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'duplicates',
                      child: Text('Find Duplicates'),
                    ),
                  ],
                ),
              ],
      ),
      body: Stack(
        children: [
          // Content
          Positioned.fill(
            child: _selectedTab == 1
                ? const CollectionsTabWidget()
                : _buildAllPhotosBody(provider),
          ),

          // Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: isSel ? _buildSelectionBottomBar(provider) : _buildFloatingBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPhotosBody(ScreenshotProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            provider.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (provider.screenshots.isEmpty) {
      return const Center(
        child: Text(
          'No screenshots indexed yet.\nTap top right icon to add photos.',
          style: TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      );
    }

    final Map<String, List<Screenshot>> groups = _groupPhotosByDay(provider.screenshots);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: groups.keys.length,
      itemBuilder: (BuildContext ctx, int index) {
        final String dateLabel = groups.keys.elementAt(index);
        final List<Screenshot> datePhotos = groups[dateLabel]!;
        final bool isDateAllSel = datePhotos.every((Screenshot s) => provider.selectedIds.contains(s.id));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  if (provider.isSelectionMode)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        backgroundColor: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        final List<String> ids = datePhotos.map((Screenshot s) => s.id).toList();
                        if (isDateAllSel) {
                          provider.deselectAll(ids);
                        } else {
                          provider.selectAll(ids);
                        }
                      },
                      child: Text(
                        isDateAllSel ? 'Deselect all' : 'Select all',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            // Grid of Photos for this date
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: datePhotos.length,
              itemBuilder: (BuildContext ctx2, int i) {
                final Screenshot s = datePhotos[i];
                final bool isSelected = provider.selectedIds.contains(s.id);

                return InkWell(
                  onLongPress: () {
                    provider.toggleSelection(s.id);
                  },
                  onTap: () {
                    if (provider.isSelectionMode) {
                      provider.toggleSelection(s.id);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ScreenshotDetailScreen(screenshot: s),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: const Color(0xFF121212),
                            child: (s.filePath.isNotEmpty && !kIsWeb)
                                ? Image.file(
                                    File(s.filePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.image_not_supported,
                                      size: 32,
                                      color: Colors.white30,
                                    ),
                                  )
                                : const Icon(Icons.image, size: 32, color: Colors.white30),
                          ),
                        ),
                      ),

                      // Outline borders/overlay if selected
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF4285F4), width: 3),
                            ),
                          ),
                        ),

                      // Selection circle in bottom-right
                      if (provider.isSelectionMode)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF4285F4) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF4285F4) : Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingBottomBar() {
    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xEE1E1E1E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // All Photos tab
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? Colors.white10 : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _selectedTab == 0 ? Icons.photo : Icons.photo_outlined,
                    color: _selectedTab == 0 ? Colors.white : Colors.white54,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Collections tab
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? Colors.white10 : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _selectedTab == 1 ? Icons.photo_library : Icons.photo_library_outlined,
                    color: _selectedTab == 1 ? Colors.white : Colors.white54,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBottomBar(ScreenshotProvider provider) {
    return Container(
      color: const Color(0xFF161616),
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSelectionAction(Icons.share, 'Send', () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Send feature triggered for ${provider.selectedIds.length} items')),
            );
          }),
          _buildSelectionAction(Icons.local_florist, 'Creativity', () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Creativity feature triggered for ${provider.selectedIds.length} items')),
            );
          }),
          _buildSelectionAction(Icons.add, 'Add to album', () {
            _showAddToAlbumDialog(context, provider.selectedIds);
          }),
          _buildSelectionAction(Icons.delete_outline, 'Delete', () async {
            final int count = provider.selectedIds.length;
            final bool? confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text('Delete Images'),
                content: Text('Are you sure you want to delete these $count images?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await provider.deleteMultipleScreenshots(provider.selectedIds.toList());
            }
          }),
        ],
      ),
    );
  }

  Widget _buildSelectionAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
