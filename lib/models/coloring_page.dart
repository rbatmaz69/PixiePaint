import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'localized_name.dart';

class ColoringPage {
  final String id;
  final String title;
  final String? titleEn;

  /// The remaining seven languages, keyed by language code (see
  /// [localizedName]). German lives in [title], English in [titleEn].
  final Map<String, String>? titles;

  final String file;

  /// German category name — also the stable grouping key for the tab bar.
  final String category;
  final String? categoryEn;

  /// "cbn" marks a color-by-number page (numbered regions, guided fill);
  /// null = regular coloring page.
  final String? mode;

  /// Which occasion this page belongs to (see [kSeasonWindows]), or null for
  /// a page that is equally at home all year.
  final String? season;

  const ColoringPage({
    required this.id,
    required this.title,
    this.titleEn,
    this.titles,
    required this.file,
    required this.category,
    this.categoryEn,
    this.mode,
    this.season,
  });

  bool get isColorByNumber => mode == 'cbn';

  String get assetPath => 'assets/coloring_pages/$file';

  String titleFor(String languageCode) =>
      localizedName(languageCode, de: title, en: titleEn, more: titles);

  /// Category names come from [kCategoryNames] rather than from every single
  /// page entry — the eight of them are shared by 68 pictures, and repeating
  /// them per page is 68 chances to spell one differently.
  String categoryFor(String languageCode) => localizedName(
        languageCode,
        de: category,
        en: categoryEn,
        more: kCategoryNames[category],
      );

  static List<ColoringPage>? _cache;

  static Future<List<ColoringPage>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/coloring_pages/pages.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => ColoringPage(
              id: e['id'] as String,
              title: e['title'] as String,
              titleEn: e['titleEn'] as String?,
              titles: namesFromJson(e['titles']),
              file: e['file'] as String,
              category: e['category'] as String,
              categoryEn: e['categoryEn'] as String?,
              mode: e['mode'] as String?,
              season: e['season'] as String?,
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

/// The picker's tab names in the seven languages that are not German (the
/// German name is the key and the stable grouping key everywhere else) and not
/// English (that one stays in `pages.json` as `categoryEn`, where it has
/// always been).
///
/// `test/page_names_test.dart` fails if a category from `pages.json` is
/// missing here — a new category otherwise shows up as a German word in the
/// middle of a Polish tab bar.
const Map<String, Map<String, String>> kCategoryNames = {
  'Tiere': {
    'es': 'Animales',
    'fr': 'Animaux',
    'it': 'Animali',
    'nl': 'Dieren',
    'pl': 'Zwierzęta',
    'pt': 'Animais',
    'tr': 'Hayvanlar',
  },
  'Natur': {
    'es': 'Naturaleza',
    'fr': 'Nature',
    'it': 'Natura',
    'nl': 'Natuur',
    'pl': 'Przyroda',
    'pt': 'Natureza',
    'tr': 'Doğa',
  },
  'Fahrzeuge': {
    'es': 'Vehículos',
    'fr': 'Véhicules',
    'it': 'Veicoli',
    'nl': 'Voertuigen',
    'pl': 'Pojazdy',
    'pt': 'Veículos',
    'tr': 'Taşıtlar',
  },
  'Fantasie': {
    'es': 'Fantasía',
    'fr': 'Fantaisie',
    'it': 'Fantasia',
    'nl': 'Fantasie',
    'pl': 'Fantazja',
    'pt': 'Fantasia',
    'tr': 'Fantezi',
  },
  'Leckereien': {
    'es': 'Golosinas',
    'fr': 'Gourmandises',
    'it': 'Dolcetti',
    'nl': 'Lekkers',
    'pl': 'Smakołyki',
    'pt': 'Guloseimas',
    'tr': 'Lezzetler',
  },
  'Weltraum': {
    'es': 'Espacio',
    'fr': 'Espace',
    'it': 'Spazio',
    'nl': 'Ruimte',
    'pl': 'Kosmos',
    'pt': 'Espaço',
    'tr': 'Uzay',
  },
  'Bauernhof': {
    'es': 'Granja',
    'fr': 'Ferme',
    'it': 'Fattoria',
    'nl': 'Boerderij',
    'pl': 'Gospodarstwo',
    'pt': 'Fazenda',
    'tr': 'Çiftlik',
  },
  'Zahlen': {
    'es': 'Números',
    'fr': 'Chiffres',
    'it': 'Numeri',
    'nl': 'Cijfers',
    'pl': 'Liczby',
    'pt': 'Números',
    'tr': 'Sayılar',
  },
  'Jahreszeiten': {
    'es': 'Estaciones',
    'fr': 'Saisons',
    'it': 'Stagioni',
    'nl': 'Seizoenen',
    'pl': 'Pory roku',
    'pt': 'Estações',
    'tr': 'Mevsimler',
  },
};

/// When each occasion is "in season", as (startMonth, startDay, endMonth,
/// endDay) with both ends inclusive.
///
/// The windows open well before the day itself — a child wants to paint the
/// Christmas tree through all of December, not on the 24th. Easter moves
/// every year, so its window simply covers the whole span it can fall in
/// (22 March to 25 April) plus a little room on either side.
const Map<String, (int, int, int, int)> kSeasonWindows = {
  'winter': (11, 25, 1, 6),
  'easter': (3, 15, 4, 30),
  'summer': (6, 1, 8, 31),
  'autumn': (9, 15, 11, 15),
  'halloween': (10, 15, 11, 2),
};

/// Whether [season] is currently in its window. An unknown season is never
/// in season, so a typo in pages.json quietly does nothing rather than
/// putting a pumpkin on the front page in June.
bool isSeasonActive(String? season, DateTime date) {
  final window = kSeasonWindows[season];
  if (window == null) return false;
  final (startMonth, startDay, endMonth, endDay) = window;
  final today = date.month * 100 + date.day;
  final start = startMonth * 100 + startDay;
  final end = endMonth * 100 + endDay;
  // A window that wraps around New Year (winter) is two ranges, not one.
  return start <= end
      ? today >= start && today <= end
      : today >= start || today <= end;
}

/// True when any page of [category] is in season right now — the signal the
/// picker uses to pull that tab to the front.
bool isCategoryInSeason(
  String category,
  List<ColoringPage> pages,
  DateTime date,
) =>
    pages.any((p) => p.category == category && isSeasonActive(p.season, date));

/// Category order for the picker: a category with something in season moves
/// to the front, everything else keeps the order of pages.json.
///
/// Deliberately stable — only the seasonal category moves, so a child does
/// not have to re-learn where "Tiere" lives every few weeks.
List<String> orderedCategories(
  List<String> categories,
  List<ColoringPage> pages,
  DateTime date,
) {
  final seasonal = <String>[];
  final rest = <String>[];
  for (final c in categories) {
    (isCategoryInSeason(c, pages, date) ? seasonal : rest).add(c);
  }
  return [...seasonal, ...rest];
}
