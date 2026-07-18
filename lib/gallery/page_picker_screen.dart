import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../canvas/canvas_screen.dart';
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
        final categories = <String>[];
        for (final p in pages) {
          if (!categories.contains(p.category)) categories.add(p.category);
        }
        final tabs = ['Alle', ...categories];
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            backgroundColor: const Color(0xFFFFF8E1),
            appBar: AppBar(
              title: const Text('Such dir ein Bild aus!'),
              backgroundColor: Colors.transparent,
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
                tabs: [for (final t in tabs) Tab(text: t)],
              ),
            ),
            body: TabBarView(
              children: [
                for (final t in tabs)
                  _PageGrid(
                    pages: t == 'Alle'
                        ? pages
                        : [for (final p in pages) if (p.category == t) p],
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
                    page.title,
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
