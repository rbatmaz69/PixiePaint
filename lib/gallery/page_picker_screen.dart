import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import 'artwork_store.dart';
import '../models/coloring_page.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/entrance.dart';
import '../ui/hero_tags.dart';
import '../ui/wait_screen.dart';
import '../ui/motion.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../ui/working_dialog.dart';
import '../util/pdf_export.dart';
import '../util/profiles.dart';
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
  'Weltraum' => PixiePalette.periwinkleLight,
  'Bauernhof' => PixiePalette.strawLight,
  'Zahlen' => PixiePalette.tangerineLight,
  'Jahreszeiten' => PixiePalette.berryLight,
  _ => PixiePalette.paperDeep,
};

class PagePickerScreen extends StatefulWidget {
  const PagePickerScreen({super.key});

  @override
  State<PagePickerScreen> createState() => _PagePickerScreenState();
}

class _PagePickerScreenState extends State<PagePickerScreen> with RouteAware {
  /// Ids of the pages this child has already painted at least once.
  ///
  /// Derived from the gallery rather than stored: [Progress] never kept a
  /// set for this, but every saved picture remembers which page it came
  /// from, and that is the same fact.
  ///
  /// Re-read when the canvas is popped back off. The picker stays alive
  /// underneath while a child paints, so without this the star for the
  /// picture they just finished would not turn up until the next time the
  /// screen was opened from scratch.
  Future<Set<String>> _painted = _loadPainted();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) pixieRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    // Block body on purpose: an arrow here hands setState the assignment's
    // value, which is a Future, and setState refuses one.
    setState(() {
      _painted = _loadPainted();
    });
  }

  @override
  void dispose() {
    pixieRouteObserver.unsubscribe(this);
    super.dispose();
  }

  static Future<Set<String>> _loadPainted() async {
    final store = ProfileStore.instance;
    final mine = store.active.id;
    final all = await ArtworkStore.list();
    return {
      for (final a in all)
        if (a.pageId != null && store.ownsArtwork(a.profileId, mine)) a.pageId!,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ColoringPage>>(
      future: ColoringPage.loadAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return PixieWaitScreen(
            emoji: '🖍️',
            title: context.l10n.pickerTitle,
            accent: PixiePalette.sunshine,
            gradient: PixieGradients.pickerBg,
            label: context.l10n.canvasLoading,
            failed: snapshot.hasError,
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
                        borderRadius: BorderRadius.circular(PixieTokens.rPill),
                        boxShadow: PixieTokens.softShadow(
                          PixiePalette.sunshine,
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.symmetric(vertical: 6),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      labelColor: scheme.primary,
                      unselectedLabelColor: scheme.onSurfaceVariant,
                      splashBorderRadius: BorderRadius.circular(PixieTokens.rPill),
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
                        // The "already painted" stars come off disk a moment
                        // later than the pictures do. They are decoration on
                        // a tile that is otherwise complete, so the grid is
                        // built without them and they appear when they are
                        // known — nobody waits on a badge.
                        child: FutureBuilder<Set<String>>(
                          future: _painted,
                          builder: (context, painted) {
                            final done = painted.data ?? const <String>{};
                            return TabBarView(
                              children: [
                                if (hasFavorites)
                                  _PageGrid(pages: favorites, painted: done),
                                _PageGrid(pages: pages, painted: done),
                                for (final c in orderedCats)
                                  _PageGrid(
                                    pages: [
                                      for (final p in pages)
                                        if (p.category == c) p,
                                    ],
                                    painted: done,
                                  ),
                              ],
                            );
                          },
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
  const _PageGrid({required this.pages, required this.painted});

  final List<ColoringPage> pages;

  /// Page ids this child has painted before.
  final Set<String> painted;

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
            if (!context.mounted) return;
            await runWithWorkingDialog(
              context: context,
              emoji: '🖨️',
              title: context.l10n.exportWorking,
              failedTitle: context.l10n.printFailed,
              work: () => printColoringPage(page),
            );
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
                        borderRadius: BorderRadius.circular(PixieTokens.rSmall),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Hero(
                        tag: pageHeroTag(page.id),
                        flightShuttleBuilder: pixieHeroShuttle,
                        child: SvgPicture.asset(
                          page.assetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: PixieTokens.gapSmall),
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
            // Two marks, both on the left: the heart owns the right corner.
            //
            // The number badge matters more than it looks. A numbered
            // picture opens into a different screen — the tool is forced to
            // the paint bucket, the palette becomes a row of numbers, and
            // most of what a child can normally do is switched off — and
            // until now its tile was indistinguishable from a picture you
            // may draw on freely.
            if (page.isColorByNumber)
              Positioned(
                bottom: 8,
                left: 8,
                // container + excludeSemantics: the badge reads as one
                // thing ("painting by numbers"), not as the glyphs "1·2·3".
                child: Semantics(
                  label: context.l10n.pageColorByNumber,
                  container: true,
                  excludeSemantics: true,
                  // Fixed size. These two marks are symbols on a tile whose
                  // aspect ratio is fixed, not prose: at 1.6x they grew into
                  // the picture and crowded the name. The screen reader gets
                  // the sentence above either way.
                  child: const MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.noScaling),
                    child: StickerPill(
                      padding: EdgeInsets.symmetric(
                          horizontal: PixieTokens.gapSmall, vertical: 2),
                      accent: PixiePalette.tangerine,
                      child: Text('1·2·3',
                          style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: PixiePalette.ink)),
                    ),
                  ),
                ),
              ),
            // The same star the tracing picker uses for a finished template
            // — a child who cannot read needs to recognise where they have
            // already been.
            if (painted.contains(page.id))
              Positioned(
                top: 8,
                left: 8,
                child: Semantics(
                  label: context.l10n.pageAlreadyPainted,
                  container: true,
                  excludeSemantics: true,
                  child: const MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.noScaling),
                    child: Text('⭐', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
          ],
        );
        // Staggered on the way in, and still arriving further down the
        // grid, where tiles are built as they are scrolled to.
        return Reveal(slot: i, child: card);
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
            duration: PixieMotion.select,
            curve: PixieCurves.spring,
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
