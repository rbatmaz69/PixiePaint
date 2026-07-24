import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/coloring_page.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/loading_pixie.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/pdf_export.dart';
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

class _PagePickerScreenState extends State<PagePickerScreen>
    with SingleTickerProviderStateMixin {
  /// Created on first use, so the entrance animation starts when the content
  /// actually appears rather than while the list is still loading.
  ///
  /// The nullable backing field is what makes that safe: leaving this screen
  /// before the load finished means `build` never touched the getter, and a
  /// plain `late final` would then *create* the controller inside dispose(),
  /// where the element tree is already deactivated — an outright crash. On a
  /// device with a big gallery and slow storage that is a very short window
  /// to hit.
  AnimationController? _entranceOrNull;
  AnimationController get _entrance => _entranceOrNull ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..forward();

  @override
  void dispose() {
    _entranceOrNull?.dispose();
    super.dispose();
  }

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
        return DefaultTabController(
          length: orderedCats.length + 1,
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
                        Tab(text: context.l10n.categoryAll),
                        for (final c in orderedCats)
                          Tab(text: categoryLabels[c]),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _PageGrid(pages: pages, entrance: _entrance),
                          for (final c in orderedCats)
                            _PageGrid(
                              pages: [
                                for (final p in pages)
                                  if (p.category == c) p,
                              ],
                              entrance: _entrance,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageGrid extends StatelessWidget {
  const _PageGrid({required this.pages, required this.entrance});

  final List<ColoringPage> pages;
  final Animation<double> entrance;

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
                  Text(
                    page.titleFor(lang),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        // One-shot staggered entrance for the first visible items only.
        if (i < 12) {
          final anim = CurvedAnimation(
            parent: entrance,
            curve: Interval(
              (0.05 * i).clamp(0.0, 0.5),
              (0.05 * i + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          );
          card = FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(anim),
              child: card,
            ),
          );
        }
        return card;
      },
    );
  }
}
