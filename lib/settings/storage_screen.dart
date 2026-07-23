import 'package:flutter/material.dart';

import '../gallery/artwork_store.dart';
import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/loading_pixie.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/sfx.dart';
import '../util/storage_usage.dart';

/// The parents' storage screen: what PixiePaint occupies, and a way to hand
/// back space by removing old pictures.
///
/// Everything here is opt-in and explicit. Nothing is preselected, nothing
/// expires on its own, and the delete button says how many pictures it is
/// about to remove — a parent clearing space should never be surprised by
/// which drawing disappeared.
class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  StorageUsage _usage = StorageUsage.empty;
  List<Artwork> _artworks = const [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final usage = await readStorageUsage();
    final artworks = await ArtworkStore.list();
    if (!mounted) return;
    setState(() {
      _usage = usage;
      // Oldest first: the pictures a parent is most likely willing to let
      // go, and the reverse of every other list in the app.
      _artworks = artworks.reversed.toList();
      _selected.removeWhere((id) => !artworks.any((a) => a.id == id));
      _loading = false;
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty || _deleting) return;
    final l10n = context.l10n;
    final confirmed = await showKidDialog<bool>(
      context: context,
      emoji: '🗑️',
      title: l10n.storageDeleteConfirm(_selected.length),
      actions: [
        Builder(
          builder: (dialogContext) => KidDialogButton(
            label: l10n.storageDeleteKeep,
            emoji: '💚',
            onTap: () => Navigator.pop(dialogContext, false),
          ),
        ),
        Builder(
          builder: (dialogContext) => KidDialogTextButton(
            label: l10n.storageDeleteGo,
            onTap: () => Navigator.pop(dialogContext, true),
          ),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    for (final artwork in _artworks.where((a) => _selected.contains(a.id))) {
      try {
        await ArtworkStore.delete(artwork);
      } catch (_) {
        // A picture that refuses to go is not worth stranding the rest.
      }
    }
    _selected.clear();
    if (!mounted) return;
    setState(() => _deleting = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: BlobBackground(
        gradient: PixieGradients.homeBg,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              PixieHeader(
                emoji: '💽',
                title: l10n.storageTitle,
                accent: PixiePalette.mint,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: LoadingPixie(emoji: '💽'))
                    : _body(context),
              ),
              if (_selected.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: KidDialogButton(
                      label: l10n.storageDeleteSelected(_selected.length),
                      emoji: '🗑️',
                      sticker: true,
                      onTap: _deleting ? () {} : _deleteSelected,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: StickerCard(
              color: Colors.white,
              radius: 24,
              shadowColor: PixiePalette.mint,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatBytes(_usage.totalBytes),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.storageBreakdown(
                      _usage.artworkCount,
                      formatBytes(_usage.artworkBytes),
                      formatBytes(_usage.stickerBytes),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PixiePalette.ink.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              _artworks.isEmpty
                  ? l10n.storageEmpty
                  : l10n.storageCleanupHint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _Tile(
                artwork: _artworks[i],
                selected: _selected.contains(_artworks[i].id),
                onTap: () {
                  Sfx.instance.tick();
                  setState(() {
                    final id = _artworks[i].id;
                    if (!_selected.remove(id)) _selected.add(id);
                  });
                },
              ),
              childCount: _artworks.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.artwork,
    required this.selected,
    required this.onTap,
  });

  final Artwork artwork;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      playTick: false,
      semanticLabel: artwork.name ?? context.l10n.storagePictureFallback,
      child: Container(
        decoration: stickerSelectionDecoration(
          selected: selected,
          accent: PixiePalette.berry,
          radius: 18,
          restColor: Colors.white,
        ),
        padding: const EdgeInsets.all(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: artwork.thumbFile.existsSync()
                  ? Image.file(
                      artwork.thumbFile,
                      fit: BoxFit.cover,
                      key: ValueKey(artwork.updatedAt),
                      cacheWidth: 320,
                      errorBuilder: (_, _, _) =>
                          const Center(child: Icon(Icons.image, size: 32)),
                    )
                  : const Center(child: Icon(Icons.image, size: 32)),
            ),
            if (selected)
              Align(
                alignment: Alignment.topRight,
                child: StickerEmoji('✅', size: 18, shadowColor: PixiePalette.berry),
              ),
          ],
        ),
      ),
    );
  }
}
