import 'dart:math';

import 'package:flutter/material.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../replay/replay_screen.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../ui/kid_dialog.dart';
import '../ui/kid_sheet.dart';
import '../ui/loading_pixie.dart';
import '../util/pdf_export.dart';
import '../util/review.dart';
import '../util/settings.dart';
import 'page_picker_screen.dart';
import '../util/save_to_photos.dart';
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

class _GalleryScreenState extends State<GalleryScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Artwork>> _future;
  bool _favoritesOnly = false;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _future = ArtworkStore.list();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = ArtworkStore.list());

  Future<void> _toggleFavorite(Artwork artwork) async {
    Sfx.instance.pop();
    await ArtworkStore.updateMeta(
      artwork.copyWith(favorite: !artwork.favorite),
    );
    // Let the heart pop finish before favorites resort to the top.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) _reload();
  }

  Future<void> _rename(Artwork artwork) async {
    final input = TextEditingController(text: artwork.name ?? '');
    final name = await showKidDialog<String>(
      context: context,
      emoji: '✏️',
      title: context.l10n.renameTitle,
      body: TextField(
        controller: input,
        autofocus: true,
        maxLength: 20,
        textCapitalization: TextCapitalization.words,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
        decoration: const InputDecoration(counterText: ''),
      ),
      actions: [
        Builder(
          builder: (dialogContext) => KidDialogButton(
            label: context.l10n.renameSave,
            emoji: '💾',
            onTap: () => Navigator.pop(dialogContext, input.text.trim()),
          ),
        ),
        Builder(
          builder: (dialogContext) => KidDialogTextButton(
            label: context.l10n.gateCancel,
            onTap: () => Navigator.pop(dialogContext),
          ),
        ),
      ],
    );
    input.dispose();
    if (name == null) return;
    await ArtworkStore.updateMeta(artwork.copyWith(name: name));
    _reload();
  }

  Future<void> _saveToPhotos(Artwork artwork) async {
    if (!await ParentalGate.show(context)) return;
    final ok = await saveArtworkToPhotos(artwork);
    if (!mounted) return;
    if (ok) {
      Sfx.instance.tada();
      showConfetti(context);
      await showKidDialog<void>(
        context: context,
        emoji: '📷',
        title: context.l10n.savedToPhotos,
        actions: [
          Builder(
            builder: (dialogContext) => KidDialogButton(
              label: context.l10n.okAction,
              emoji: '🎉',
              onTap: () => Navigator.pop(dialogContext),
            ),
          ),
        ],
      );
    } else {
      await showKidDialog<void>(
        context: context,
        emoji: '😕',
        title: context.l10n.saveToPhotosFailedTitle,
        body: Text(
          context.l10n.saveToPhotosFailed,
          textAlign: TextAlign.center,
        ),
        actions: [
          Builder(
            builder: (dialogContext) => KidDialogButton(
              label: context.l10n.okAction,
              onTap: () => Navigator.pop(dialogContext),
            ),
          ),
        ],
      );
    }
  }

  Future<void> _open(Artwork artwork) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CanvasScreen(resume: artwork)));
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
            if (artwork.opsFile.existsSync()) ...[
              const SizedBox(height: 10),
              Builder(
                builder: (sheetContext) => KidDialogButton(
                  emoji: '🎬',
                  label: context.l10n.replayAction,
                  gradient: PixieGradients.freeDraw,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => ReplayScreen(artwork: artwork)),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            Builder(
              builder: (sheetContext) => KidDialogButton(
                emoji: '✏️',
                label: context.l10n.renameAction,
                gradient: PixieGradients.freeDraw,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _rename(artwork);
                },
              ),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (sheetContext) => KidDialogButton(
                emoji: '📷',
                label: context.l10n.saveToPhotos,
                gradient: PixieGradients.gallery,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _saveToPhotos(artwork);
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
            const SizedBox(height: 10),
            Builder(
              builder: (sheetContext) => KidDialogButton(
                emoji: '🖨️',
                label: context.l10n.printForParents,
                gradient: PixieGradients.trace,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _print(artwork);
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

  Future<void> _print(Artwork artwork) async {
    if (!await ParentalGate.show(context)) return;
    try {
      await printSavedArtwork(artwork);
    } catch (_) {
      // The native print dialog can fail on odd printers — never crash.
    }
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
      body: BlobBackground(
        gradient: PixieGradients.galleryBg,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              PixieHeader(
                emoji: '🖼️',
                title: context.l10n.galleryTitle,
                accent: PixiePalette.mint,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<List<Artwork>>(
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: KidDialogButton(
                    emoji: '🖍️',
                    label: context.l10n.galleryEmptyCta,
                    gradient: PixieGradients.coloring,
                    sticker: true,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const PagePickerScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        // Favorites bubble to the top, then newest first (list() is
        // already sorted by updatedAt).
        final sorted = [
          ...artworks.where((a) => a.favorite),
          ...artworks.where((a) => !a.favorite),
        ];
        final shown = _favoritesOnly
            ? sorted.where((a) => a.favorite).toList()
            : sorted;
        final hasFavorites = artworks.any((a) => a.favorite);
        return Column(
          children: [
            if (hasFavorites)
              _staggered(
                0,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: context.l10n.filterAll,
                        selected: !_favoritesOnly,
                        onTap: () => setState(() => _favoritesOnly = false),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '❤️ ${context.l10n.filterFavorites}',
                        selected: _favoritesOnly,
                        onTap: () => setState(() => _favoritesOnly = true),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 4 / 3.4,
                ),
                itemCount: shown.length,
                itemBuilder: (context, i) {
                  Widget card = _PolaroidCard(
                    artwork: shown[i],
                    tiltIndex: i,
                    onTap: () => _open(shown[i]),
                    onLongPress: () => _showItemMenu(shown[i]),
                    onToggleFavorite: () => _toggleFavorite(shown[i]),
                  );
                  // One-shot staggered entrance for the first visible
                  // items only (matches the page picker).
                  if (i < 12) card = _staggered(i + 1, card);
                  return card;
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Fade + rise on the shared entrance controller, slot-staggered.
  Widget _staggered(int slot, Widget child) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        (0.05 * slot).clamp(0.0, 0.5),
        (0.05 * slot + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }
}

/// "Polaroid" card: white frame, soft shadow, wider bottom edge carrying
/// the kid-given name, heart toggle floating on the photo corner. The heart
/// flips with a springy scale and fires a tiny burst when favorited —
/// optimistic local state so feedback is instant despite the async store.
class _PolaroidCard extends StatefulWidget {
  const _PolaroidCard({
    required this.artwork,
    required this.tiltIndex,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleFavorite,
  });

  final Artwork artwork;
  final int tiltIndex;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleFavorite;

  @override
  State<_PolaroidCard> createState() => _PolaroidCardState();
}

class _PolaroidCardState extends State<_PolaroidCard>
    with SingleTickerProviderStateMixin {
  late bool _fav = widget.artwork.favorite;
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void didUpdateWidget(_PolaroidCard old) {
    super.didUpdateWidget(old);
    _fav = widget.artwork.favorite;
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _onHeartTap() {
    setState(() => _fav = !_fav);
    if (_fav) _burst.forward(from: 0);
    widget.onToggleFavorite();
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    final hasName = artwork.name?.isNotEmpty ?? false;
    return Bouncy(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      // The white polaroid frame IS the sticker border — tilt + colored
      // shadow complete the stuck-on look.
      child: Transform.rotate(
        angle: PixieTokens.stickerTilt(widget.tiltIndex),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: PixieTokens.softShadow(PixiePalette.mint),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 26),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: artwork.thumbFile.existsSync()
                        ? Image.file(
                            artwork.thumbFile,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            // Thumbnails change on disk under the same path,
                            // so don't let the image cache serve stale ones.
                            key: ValueKey(artwork.updatedAt),
                            cacheWidth: 560,
                          )
                        : const Center(child: Icon(Icons.image, size: 48)),
                  ),
                ),
              ),
              if (hasName)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 3,
                  child: Text(
                    artwork.name!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              // Heart burst lives in a full-card layer: the 40px button would
              // clip it.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _burst,
                    builder: (context, _) =>
                        CustomPaint(painter: _HeartBurstPainter(_burst.value)),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: StickerCircleButton(
                  onTap: _onHeartTap,
                  playTick: false,
                  size: 40,
                  accent: PixiePalette.berry,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutBack,
                      ),
                      child: child,
                    ),
                    child: Text(
                      _fav ? '❤️' : '🤍',
                      key: ValueKey(_fav),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six tiny pink dots flying outward from the heart's corner, fading out.
class _HeartBurstPainter extends CustomPainter {
  _HeartBurstPainter(this.t);

  final double t;

  static const List<Color> _pinks = [
    PixiePalette.berry,
    PixiePalette.bubblegumLight,
    PixiePalette.bubblegum,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = Offset(size.width - 24, 24);
    final eased = Curves.easeOutCubic.transform(t);
    final radius = 10 + eased * 22;
    final paint = Paint();
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + 0.4;
      paint.color = _pinks[i % 3].withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * radius,
        3.5 * (1 - eased) + 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeartBurstPainter old) => old.t != t;
}

/// Bouncy pill chip for the Alle/Favoriten filter row.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Bouncy(
      onTap: onTap,
      playTick: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: stickerSelectionDecoration(
          selected: selected,
          accent: PixiePalette.mint,
          restColor: Colors.white.withValues(alpha: 0.6),
          radius: 22,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: selected ? PixiePalette.ink : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
