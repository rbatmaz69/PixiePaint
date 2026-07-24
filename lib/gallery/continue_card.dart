import 'package:flutter/material.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/pixie_palette.dart';
import '../util/profiles.dart';
import 'artwork_store.dart';

/// "Keep painting" — the picture this child touched last, one tap away.
///
/// Without it the way back into yesterday's picture is home → gallery →
/// find the tile → tap, and a child who cannot read has to recognise their
/// own thumbnail among all the others to get there. This is the single most
/// likely thing they want when they open the app.
///
/// Renders nothing at all until there *is* a picture, so a fresh device
/// looks exactly as it did before.
class ContinueCard extends StatefulWidget {
  const ContinueCard({super.key, required this.width});

  final double width;

  @override
  State<ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends State<ContinueCard> with RouteAware {
  Artwork? _latest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) pixieRouteObserver.subscribe(this, route);
  }

  /// Coming back from the canvas or the gallery: what "last" means has very
  /// likely just changed — that is the whole point of this card.
  @override
  void didPopNext() => _load();

  @override
  void dispose() {
    pixieRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final store = ProfileStore.instance;
      final activeId = store.active.id;
      // The list arrives newest-first, so the first picture this child owns
      // is the one they left off in.
      final all = await ArtworkStore.list();
      final mine = all
          .where((a) => store.ownsArtwork(a.profileId, activeId))
          .toList();
      if (!mounted) return;
      setState(() => _latest = mine.isEmpty ? null : mine.first);
    } catch (_) {
      // A shortcut is not worth a broken home screen.
      if (mounted) setState(() => _latest = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artwork = _latest;
    if (artwork == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Bouncy(
        minSize: 0,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CanvasScreen(resume: artwork),
            ),
          );
        },
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: PixieTokens.softShadow(PixiePalette.mint),
          ),
          child: Row(
            children: [
              // The thumbnail is the label for a child who cannot read; the
              // words next to it are for whoever reads over their shoulder.
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  artwork.thumbFile,
                  width: 64,
                  height: 48,
                  fit: BoxFit.cover,
                  cacheWidth: 128,
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 64,
                    height: 48,
                    child: Center(child: Text('🎨')),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.continuePainting,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if ((artwork.name ?? '').isNotEmpty)
                      Text(
                        artwork.name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              const Text('🖌️', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
