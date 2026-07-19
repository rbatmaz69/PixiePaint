import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/coloring_page.dart';

class PagePickerScreen extends StatelessWidget {
  const PagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ColoringPage>>(
      future: ColoringPage.loadAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFF8E1),
            body: Center(child: CircularProgressIndicator()),
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
        return DefaultTabController(
          length: categories.length + 1,
          child: Scaffold(
            backgroundColor: const Color(0xFFFFF8E1),
            appBar: AppBar(
              title: Text(context.l10n.pickerTitle),
              backgroundColor: Colors.transparent,
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: context.l10n.categoryAll),
                  for (final c in categories) Tab(text: categoryLabels[c]),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _PageGrid(pages: pages),
                for (final c in categories)
                  _PageGrid(
                    pages: [for (final p in pages) if (p.category == c) p],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageGrid extends StatelessWidget {
  const _PageGrid({required this.pages});

  final List<ColoringPage> pages;

  @override
  Widget build(BuildContext context) {
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
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CanvasScreen(page: page)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: SvgPicture.asset(
                      page.assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    page.titleFor(
                        Localizations.localeOf(context).languageCode),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
