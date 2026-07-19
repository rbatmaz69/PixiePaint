import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/coloring_page.dart';
import '../ui/app_theme.dart';
import '../ui/bouncy.dart';
import '../ui/loading_pixie.dart';

/// Soft tint per category (keyed by the stable German category name).
Color _categoryTint(String category) => switch (category) {
      'Tiere' => const Color(0xFFFFF3E0),
      'Natur' => const Color(0xFFE8F5E9),
      'Fahrzeuge' => const Color(0xFFE3F2FD),
      'Fantasie' => const Color(0xFFF3E5F5),
      'Leckereien' => const Color(0xFFFFF0F3),
      'Weltraum' => const Color(0xFFE8EAF6),
      _ => const Color(0xFFF5F5F5),
    };

class PagePickerScreen extends StatefulWidget {
  const PagePickerScreen({super.key});

  @override
  State<PagePickerScreen> createState() => _PagePickerScreenState();
}

class _PagePickerScreenState extends State<PagePickerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ColoringPage>>(
      future: ColoringPage.loadAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Container(
              decoration:
                  const BoxDecoration(gradient: PixieGradients.pickerBg),
              child: const Center(child: LoadingPixie()),
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
        final scheme = Theme.of(context).colorScheme;
        return DefaultTabController(
          length: categories.length + 1,
          child: Scaffold(
            body: Container(
              decoration:
                  const BoxDecoration(gradient: PixieGradients.pickerBg),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Row(
                        children: [
                          Bouncy(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_back_rounded,
                                  color: scheme.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.pickerTitle,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding:
                          const EdgeInsets.symmetric(vertical: 6),
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      labelColor: scheme.primary,
                      unselectedLabelColor: scheme.onSurfaceVariant,
                      splashBorderRadius: BorderRadius.circular(24),
                      tabs: [
                        Tab(text: context.l10n.categoryAll),
                        for (final c in categories)
                          Tab(text: categoryLabels[c]),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _PageGrid(pages: pages, entrance: _entrance),
                          for (final c in categories)
                            _PageGrid(
                              pages: [
                                for (final p in pages)
                                  if (p.category == c) p
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
        Widget card = Bouncy(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CanvasScreen(page: page)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(24),
              boxShadow: PixieTokens.softShadow(tint),
            ),
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
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
                      begin: const Offset(0, 0.12), end: Offset.zero)
                  .animate(anim),
              child: card,
            ),
          );
        }
        return card;
      },
    );
  }
}
