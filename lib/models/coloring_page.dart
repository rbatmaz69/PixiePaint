import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ColoringPage {
  final String id;
  final String title;
  final String file;
  final String category;

  const ColoringPage({
    required this.id,
    required this.title,
    required this.file,
    required this.category,
  });

  String get assetPath => 'assets/coloring_pages/$file';

  static List<ColoringPage>? _cache;

  static Future<List<ColoringPage>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/coloring_pages/pages.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => ColoringPage(
              id: e['id'] as String,
              title: e['title'] as String,
              file: e['file'] as String,
              category: e['category'] as String,
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
