// lib/presentation/widgets/collections_tab_widget.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/screenshot_model.dart';
import '../../domain/models/album_model.dart';
import '../providers/screenshot_provider.dart';
import '../screens/album_detail_screen.dart';

class CollectionsTabWidget extends StatefulWidget {
  const CollectionsTabWidget({super.key});

  @override
  State<CollectionsTabWidget> createState() => _CollectionsTabWidgetState();
}

class _CollectionsTabWidgetState extends State<CollectionsTabWidget> {
  final Map<String, String> _categoryDisplayNames = const <String, String>{
    'receipts_invoices': 'Receipts & Invoices',
    'screenshots': 'Screenshots',
    'documents': 'Documents',
    'identification': 'Identification',
    'memes_social': 'Memes & Social',
    'travel_tickets': 'Travel & Tickets',
    'food_menus': 'Food & Menus',
    'code_tech': 'Code & Tech',
    'people_portraits': 'People & Portraits',
    'nature_scenery': 'Nature & Scenery',
    'other': 'Other',
  };

  final Map<String, IconData> _categoryIcons = const <String, IconData>{
    'receipts_invoices': Icons.receipt_long,
    'screenshots': Icons.screenshot,
    'documents': Icons.description,
    'identification': Icons.badge,
    'memes_social': Icons.sentiment_very_satisfied,
    'travel_tickets': Icons.airplane_ticket,
    'food_menus': Icons.restaurant_menu,
    'code_tech': Icons.code,
    'people_portraits': Icons.people,
    'nature_scenery': Icons.landscape,
    'other': Icons.folder_open,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScreenshotProvider>().loadAlbums();
    });
  }

  void _showCreateAlbumDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('New Album'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter album name',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                final String name = controller.text.trim();
                if (name.isNotEmpty) {
                  context.read<ScreenshotProvider>().createAlbum(name);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Create', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScreenshotProvider provider = context.watch<ScreenshotProvider>();
    
    // Pinned Counts & Thumbs
    final int allCount = provider.screenshots.length;
    final String allThumb = provider.screenshots.isNotEmpty ? provider.screenshots.first.filePath : '';
    
    final List<Screenshot> cameraPhotos = provider.screenshots
        .where((Screenshot s) => s.filePath.toLowerCase().contains('camera'))
        .toList();
    final int cameraCount = cameraPhotos.length;
    final String cameraThumb = cameraPhotos.isNotEmpty ? cameraPhotos.first.filePath : '';

    final List<Screenshot> screenshotPhotos = provider.screenshots
        .where((Screenshot s) => s.category == 'screenshots')
        .toList();
    final int screenCount = screenshotPhotos.length;
    final String screenThumb = screenshotPhotos.isNotEmpty ? screenshotPhotos.first.filePath : '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pinned Section
        const Row(
          children: [
            Text(
              'Pinned',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _buildPinnedCard(context, 'All photos', allCount, allThumb, Icons.photo, () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const AlbumDetailScreen(title: 'All photos'),
              ));
            }),
            _buildPinnedCard(context, 'Camera', cameraCount, cameraThumb, Icons.camera_alt, () {
              // Open Camera category or filter
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const AlbumDetailScreen(title: 'Camera'),
              ));
            }),
            _buildPinnedCard(context, 'Screenshots', screenCount, screenThumb, Icons.phonelink_setup, () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const AlbumDetailScreen(title: 'Screenshots', categoryKey: 'screenshots'),
              ));
            }),
            _buildPinnedCard(context, 'Videos', 0, '', Icons.videocam, () {}),
            _buildPinnedCard(context, 'Favourites', 0, '', Icons.favorite, () {}),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Albums Section
        Row(
          children: [
            const Text(
              'Albums',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showCreateAlbumDialog(context),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
        const SizedBox(height: 12),
        
        // Grid of Albums
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: provider.albums.length + _categoryDisplayNames.length + 1,
          itemBuilder: (BuildContext ctx, int index) {
            if (index == 0) {
              // Create Album Card
              return _buildCreateAlbumCard();
            }
            
            final int customIndex = index - 1;
            if (customIndex < provider.albums.length) {
              // Custom User Album
              final Album album = provider.albums[customIndex];
              return FutureBuilder<List<Screenshot>>(
                future: provider.getScreenshotsForAlbum(album.id),
                builder: (BuildContext c, AsyncSnapshot<List<Screenshot>> snap) {
                  final List<Screenshot> photos = snap.data ?? <Screenshot>[];
                  final String thumb = photos.isNotEmpty ? photos.first.filePath : '';
                  return _buildAlbumGridCard(
                    context,
                    album.name,
                    photos.length,
                    thumb,
                    Icons.folder,
                    () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => AlbumDetailScreen(
                          title: album.name,
                          customAlbum: album,
                        ),
                      ));
                    },
                  );
                },
              );
            }
            
            // Predefined Category Album
            final int catIndex = customIndex - provider.albums.length;
            final String catKey = _categoryDisplayNames.keys.elementAt(catIndex);
            final String catName = _categoryDisplayNames[catKey]!;
            final IconData catIcon = _categoryIcons[catKey]!;
            
            final List<Screenshot> catPhotos = provider.screenshots
                .where((Screenshot s) => s.category == catKey)
                .toList();
            final String catThumb = catPhotos.isNotEmpty ? catPhotos.first.filePath : '';
            
            return _buildAlbumGridCard(
              context,
              catName,
              catPhotos.length,
              catThumb,
              catIcon,
              () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => AlbumDetailScreen(
                    title: catName,
                    categoryKey: catKey,
                  ),
                ));
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPinnedCard(
    BuildContext context,
    String title,
    int count,
    String thumbPath,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                color: Colors.grey[900],
                child: (thumbPath.isNotEmpty && !kIsWeb)
                    ? Image.file(
                        File(thumbPath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(icon, color: Colors.white54, size: 20),
                      )
                    : Icon(icon, color: Colors.white54, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // Title & Count
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAlbumCard() {
    return InkWell(
      onTap: () => _showCreateAlbumDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, style: BorderStyle.values[1]), // dotted style mock via thin dashed appearance
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white70, size: 28),
            SizedBox(height: 8),
            Text(
              'Create Album',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumGridCard(
    BuildContext context,
    String name,
    int count,
    String thumbPath,
    IconData defaultIcon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color(0xFF1E1E1E),
                      child: (thumbPath.isNotEmpty && !kIsWeb)
                          ? Image.file(
                              File(thumbPath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(defaultIcon, color: Colors.white54, size: 36),
                            )
                          : Icon(defaultIcon, color: Colors.white54, size: 36),
                    ),
                  ),
                ),
                // Offline Cloud Icon (crossed cloud) in top right
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
