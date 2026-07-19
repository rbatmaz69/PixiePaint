import 'package:flutter/material.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../ui/app_theme.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/kid_sheet.dart';
import '../ui/loading_pixie.dart';
import '../util/review.dart';
import '../util/settings.dart';
import 'page_picker_screen.dart';
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
    await showKidSheet<void>(
      context: context,
      emoji: '🖼️',
      title: context.l10n.galleryTitle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(
              builder: (sheetContext) => KidDialogButton(
                emoji: '🖌️',
                label: context.l10n.continuePainting,
                gradient: PixieGradients.coloring,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(artwork);
                },
              ),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (sheetContext) => KidDialogButton(
                emoji: '💌',
                label: context.l10n.shareForParents,
                gradient: PixieGradients.photo,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _share(artwork);
                },
              ),
            ),
            const SizedBox(height: 6),
            Builder(
              builder: (sheetContext) => KidDialogTextButton(
                label: context.l10n.deleteAction,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _delete(artwork);
                },
              ),
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
      appBar: AppBar(
        title: Text(context.l10n.galleryTitle),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: const BoxDecoration(gradient: PixieGradients.galleryBg),
        child: FutureBuilder<List<Artwork>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: LoadingPixie());
            }
            final artworks = snapshot.data!;
            if (artworks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LoadingPixie(emoji: '🖼️'),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.galleryEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const PagePickerScreen()),
                      ),
                      icon: const Icon(Icons.color_lens_rounded),
                      label: Text(context.l10n.galleryEmptyCta),
                    ),
                  ],
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 4 / 3.4,
              ),
              itemCount: artworks.length,
              itemBuilder: (context, i) {
                final artwork = artworks[i];
                // "Polaroid": white frame, soft shadow, wider bottom edge.
                return Bouncy(
                  onTap: () => _open(artwork),
                  onLongPress: () => _showItemMenu(artwork),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 22),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: artwork.thumbFile.existsSync()
                          ? Image.file(
                              artwork.thumbFile,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              // Thumbnails change on disk under the same
                              // path, so don't let the image cache serve
                              // stale ones.
                              key: ValueKey(artwork.updatedAt),
                              cacheWidth: 560,
                            )
                          : const Center(child: Icon(Icons.image, size: 48)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
