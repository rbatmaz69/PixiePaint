import 'package:flutter/material.dart';

import '../canvas/canvas_screen.dart';
import '../models/artwork.dart';
import '../util/settings.dart';
import '../util/sfx.dart';
import '../util/share.dart' as share_util;
import '../widgets/parental_gate.dart';
import 'artwork_store.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<List<Artwork>> _future;

  @override
  void initState() {
    super.initState();
    _future = ArtworkStore.list();
  }

  void _reload() => setState(() => _future = ArtworkStore.list());

  Future<void> _open(Artwork artwork) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CanvasScreen(resume: artwork)),
    );
    _reload();
  }

  Future<void> _showItemMenu(Artwork artwork) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brush_rounded, size: 32),
              title: const Text('Weitermalen', style: TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.pop(sheetContext);
                _open(artwork);
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded, size: 32),
              title: const Text('Teilen (für Eltern)',
                  style: TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.pop(sheetContext);
                _share(artwork);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, size: 32),
              title: const Text('Wegwerfen', style: TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.pop(sheetContext);
                _delete(artwork);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(Artwork artwork) async {
    if (!await ParentalGate.show(context)) return;
    Sfx.instance.tada();
    await share_util.shareSavedArtwork(artwork);
  }

  Future<void> _delete(Artwork artwork) async {
    if (Settings.instance.deleteNeedsGate) {
      if (!await ParentalGate.show(context)) return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bild wegwerfen?'),
        content: const Text('Das Bild ist dann für immer weg.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Behalten!'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wegwerfen'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ArtworkStore.delete(artwork);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Meine Bilder'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Artwork>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final artworks = snapshot.data!;
          if (artworks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🖼️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text(
                    'Noch keine Bilder –\nmal doch eins!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 4 / 3,
            ),
            itemCount: artworks.length,
            itemBuilder: (context, i) {
              final artwork = artworks[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(artwork),
                  onLongPress: () => _showItemMenu(artwork),
                  child: artwork.thumbFile.existsSync()
                      ? Image.file(
                          artwork.thumbFile,
                          fit: BoxFit.cover,
                          // Thumbnails change on disk under the same path,
                          // so don't let the image cache serve stale ones.
                          key: ValueKey(artwork.updatedAt),
                          cacheWidth: 560,
                        )
                      : const Icon(Icons.image, size: 48),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
