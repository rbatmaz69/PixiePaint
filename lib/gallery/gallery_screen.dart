import 'package:flutter/material.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../ui/kid_dialog.dart';
import '../util/review.dart';
import '../util/settings.dart';
import '../util/sfx.dart';
import '../util/share.dart' as share_util;
import '../widgets/confetti_burst.dart';
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
              title: Text(context.l10n.continuePainting,
                  style: const TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.pop(sheetContext);
                _open(artwork);
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded, size: 32),
              title: Text(context.l10n.shareForParents,
                  style: const TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.pop(sheetContext);
                _share(artwork);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, size: 32),
              title: Text(context.l10n.deleteAction,
                  style: const TextStyle(fontSize: 18)),
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
    if (mounted) showConfetti(context);
    await countShareAndMaybeReview();
  }

  Future<void> _delete(Artwork artwork) async {
    if (Settings.instance.deleteNeedsGate) {
      if (!await ParentalGate.show(context)) return;
    }
    if (!mounted) return;
    final ok = await showKidDialog<bool>(
      context: context,
      emoji: '🗑️',
      title: context.l10n.deleteTitle,
      body: Text(context.l10n.deleteBody, textAlign: TextAlign.center),
      actions: [
        Builder(
          builder: (context) => KidDialogButton(
            label: context.l10n.deleteKeep,
            emoji: '💚',
            onTap: () => Navigator.pop(context, false),
          ),
        ),
        Builder(
          builder: (context) => KidDialogTextButton(
            label: context.l10n.deleteAction,
            onTap: () => Navigator.pop(context, true),
          ),
        ),
      ],
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
        title: Text(context.l10n.galleryTitle),
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
                    context.l10n.galleryEmpty,
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
