import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ColoringPage {
  final String id;
  final String title;
  final String? titleEn;
  final String file;

  /// German category name — also the stable grouping key for the tab bar.
  final String category;
  final String? categoryEn;

  /// "cbn" marks a color-by-number page (numbered regions, guided fill);
  /// null = regular coloring page.
  final String? mode;

  const ColoringPage({
    required this.id,
    required this.title,
    this.titleEn,
    required this.file,
    required this.category,
    this.categoryEn,
    this.mode,
  });

  bool get isColorByNumber => mode == 'cbn';

  String get assetPath => 'assets/coloring_pages/$file';

  String titleFor(String languageCode) =>
      languageCode == 'en' ? (titleEn ?? title) : title;

  String categoryFor(String languageCode) =>
      languageCode == 'en' ? (categoryEn ?? category) : category;

  static List<ColoringPage>? _cache;

  static Future<List<ColoringPage>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/coloring_pages/pages.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => ColoringPage(
              id: e['id'] as String,
              title: e['title'] as String,
              titleEn: e['titleEn'] as String?,
              file: e['file'] as String,
              category: e['category'] as String,
              categoryEn: e['categoryEn'] as String?,
              mode: e['mode'] as String?,
            ))
        .toList();
    _cache = list;
    return list;
  }

  static Future<ColoringPage?> byId(String id) async {
    final all = await loadAll();
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
