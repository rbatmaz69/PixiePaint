import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'localized_name.dart';

/// A ready-made colored background stage the kid stamps and paints on —
/// technically a photo-mode background, so saving/export/replay reuse the
/// photo plumbing unchanged.
class Scene {
  final String id;
  final String title;
  final String? titleEn;

  /// The other seven languages, keyed by language code — see [localizedName].
  final Map<String, String>? titles;

  final String file;

  const Scene({
    required this.id,
    required this.title,
    this.titleEn,
    this.titles,
    required this.file,
  });

  String get assetPath => 'assets/scenes/$file';

  String titleFor(String languageCode) =>
      localizedName(languageCode, de: title, en: titleEn, more: titles);

  static List<Scene>? _cache;

  static Future<List<Scene>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/scenes/scenes.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Scene(
              id: e['id'] as String,
              title: e['title'] as String,
              titleEn: e['titleEn'] as String?,
              titles: namesFromJson(e['titles']),
              file: e['file'] as String,
            ))
        .toList();
    _cache = list;
    return list;
  }
}
