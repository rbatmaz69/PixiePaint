import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/coloring_page.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/entrance.dart';
import '../ui/loading_pixie.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/pdf_export.dart';
import '../util/progress.dart';
import '../util/sfx.dart';
import '../widgets/parental_gate.dart';

/// Soft tint per category (keyed by the stable German category name),
/// derived from the PixiePalette.
Color _categoryTint(String category) => switch (category) {
  'Tiere' => PixiePalette.sunshineLight,
  'Natur' => PixiePalette.mintLight,
  'Fahrzeuge' => PixiePalette.skyLight,
  'Fantasie' => PixiePalette.grapeLight,
  'Leckereien' => PixiePalette.bubblegumLight,
  'Weltraum' => const Color(0xFFE2E0FF),
  'Bauernhof' => const Color(0xFFE8E3CF),
  'Zahlen' => PixiePalette.tangerineLight,
  'Jahreszeiten' => const Color(0xFFFFE0DC),
  _ => const Color(0xFFF5F0E8),
};

class PagePickerScreen extends StatefulWidget {
  const PagePickerScreen({super.key});

  @override
  State<PagePickerScreen> createState() => _PagePickerScreenState();
}

class _PagePickerScreenState extends State<PagePickerScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ColoringPage>>(
      future: ColoringPage.loadAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: BlobBackground(
              gradient: PixieGradients.pickerBg,
              builder: (context, _) => const Center(child: LoadingPixie()),
            ),
          );
        }
        final pages = snapshot.data!;
        final lang = Localizations.localeOf(context).languageCode;
        // Group by the German category (stable key); display localized.
        final categories = <String>[];
        final categoryLabels = <String, String>{};
        for (final p in pages) {
          if (!categories.contains(p.category)) {
            categories.add(p.category);
            categoryLabels[p.category] = p.categoryFor(lang);
          }
        }
        // Whatever is in season right now comes first — in December the
        // Christmas tree should be one tap away, not four tabs along.
        final orderedCats =
            orderedCategories(categories, pages, DateTime.now());
        final scheme = Theme.of(context).colorScheme;
        return ListenableBuilder(
          listenable: Progress.instance,
          builder: (context, _) {
            final favorites = [
              for (final p in pages)
                if (Progress.instance.isFavoritePage(p.id)) p,
            ];
            return _pickerBody(
                context, pages, favorites, orderedCats, categoryLabels,
                scheme: scheme, lang: lang);
          },
        );
      },
    );
  }

  /// The tabs. The hearts tab only exists once something is in it — an
  /// empty first tab would greet every new child with a blank screen.
  ///
  /// Its presence changes the tab count, so the controller is keyed on that
  /// count: rebuilding a [DefaultTabController] with a different length and
  /// the same state is exactly the case Flutter asserts on.
  Widget _pickerBody(
    BuildContext context,
    List<ColoringPage> pages,
    List<ColoringPage> favorites,
    List<String> orderedCats,
    Map<String, String> categoryLabels, {
    required ColorScheme scheme,
    required String lang,
  }) {
    final hasFavorites = favorites.isNotEmpty;
    return DefaultTabController(
          key: ValueKey(hasFavorites),
          length: orderedCats.length + (hasFavorites ? 2 : 1),
          child: Scaffold(
            body: BlobBackground(
              gradient: PixieGradients.pickerBg,
              builder: (context, _) => SafeArea(
                child: Column(
                  children: [
                    PixieHeader(
                      emoji: '🖍️',
                      title: context.l10n.pickerTitle,
                      accent: PixiePalette.sunshine,
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: PixieTokens.softShadow(
                          PixiePalette.sunshine,
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.symmetric(vertical: 6),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      labelColor: scheme.primary,
                      unselectedLabelColor: scheme.onSurfaceVariant,
                      splashBorderRadius: BorderRadius.circular(24),
                      tabs: [
                        if (hasFavorites) const Tab(text: '💖'),
                        Tab(text: context.l10n.categoryAll),
                        for (final c in orderedCats)
                          Tab(text: categoryLabels[c]),
                      ],
                    ),
                    // Inside the loaded branch on purpose: the cascade
                    // starts when the pictures are actually there, not
                    // while the list is still coming off disk.
                    Expanded(
                      child: EntranceGroup(
                        child: TabBarView(
                          children: [
                            if (hasFavorites) _PageGrid(pages: favorites),
                            _PageGrid(pages: pages),
                            for (final c in orderedCats)
                              _PageGrid(
                                pages: [
                                  for (final p in pages)
                                    if (p.category == c) p,
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }
}

class _PageGrid extends StatelessWidget {
  const _PageGrid({required this.pages});

  final List<ColoringPage> pages;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: pages.length,
      itemBuilder: (context, i) {
        final page = pages[i];
        final tint = _categoryTint(page.category);
        // Long-press: print the blank page for real-paper coloring
        // (parent feature, guarded by the gate — deliberately quiet UI).
        Widget card = GestureDetector(
          onLongPress: () async {
            if (!await ParentalGate.show(context)) return;
            try {
              await printColoringPage(page);
            } catch (_) {}
          },
          child: Bouncy(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => CanvasScreen(page: page))),
            child: StickerCard(
              color: tint,
              radius: 24,
              tiltIndex: i,
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Hero(
                        tag: page.id,
                        child: SvgPicture.asset(
                          page.assetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // One line, and it may shrink: the tiles form a grid with
                  // a fixed aspect ratio, so a long name at a large system
                  // font has to give rather than push the picture out.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        page.titleFor(lang),
                        maxLines: 1,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        // The heart sits *on* the card rather than being a long-press: the
        // long-press is the parents' print shortcut, and a child who cannot
        // read needs the mark they made to be visible without holding
        // anything down.
        card = Stack(
          children: [
            card,
            Positioned(top: 0, right: 0, child: _FavoriteHeart(page: page)),
          ],
        );
        // One-shot staggered entrance for the first visible items only.
        if (i < 12) card = Entrance(slot: i, child: card);
        return card;
      },
    );
  }
}

/// The heart in the corner of a picture tile.
///
/// Per child (it lives in that child's progress file), and it is the only
/// way back to a favourite motif that does not involve reading a tab label.
class _FavoriteHeart extends StatelessWidget {
  const _FavoriteHeart({required this.page});

  final ColoringPage page;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final on = Progress.instance.isFavoritePage(page.id);
        return Bouncy(
          onTap: () {
            Progress.instance.toggleFavoritePage(page.id);
            Sfx.instance.pop();
          },
          playTick: false,
          semanticLabel: context.l10n.favoritePageAction,
          semanticSelected: on,
          child: AnimatedScale(
            scale: on ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: on ? 0.95 : 0.7),
                shape: BoxShape.circle,
                boxShadow: PixieTokens.softShadow(PixiePalette.bubblegum),
              ),
              child: Icon(
                on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
                color: on
                    ? PixiePalette.bubblegum
                    : PixiePalette.ink.withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      },
    );
  }
}
