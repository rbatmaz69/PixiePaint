import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/models/coloring_page.dart';

/// Two things are checked here: that the seasonal windows behave across the
/// awkward dates (New Year, the day before a window opens), and that every
/// new SVG actually works as a coloring page.
///
/// The second half is the important one. A drawing with a gap in its
/// outline looks perfect and floods the whole picture on the first tap —
/// which no unit test of the fill algorithm would ever catch, because the
/// algorithm is right and the artwork is wrong.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('season windows', () {
    test('winter wraps around New Year', () {
      expect(isSeasonActive('winter', DateTime(2026, 12, 24)), isTrue);
      expect(isSeasonActive('winter', DateTime(2026, 12, 31)), isTrue);
      expect(isSeasonActive('winter', DateTime(2027, 1, 1)), isTrue);
      expect(isSeasonActive('winter', DateTime(2027, 1, 6)), isTrue);
      // ...and closes again.
      expect(isSeasonActive('winter', DateTime(2027, 1, 7)), isFalse);
      expect(isSeasonActive('winter', DateTime(2026, 11, 24)), isFalse);
    });

    test('both ends of a window are inclusive', () {
      expect(isSeasonActive('summer', DateTime(2026, 6, 1)), isTrue);
      expect(isSeasonActive('summer', DateTime(2026, 8, 31)), isTrue);
      expect(isSeasonActive('summer', DateTime(2026, 5, 31)), isFalse);
      expect(isSeasonActive('summer', DateTime(2026, 9, 1)), isFalse);
    });

    test('easter covers every date easter can fall on', () {
      // Easter Sunday ranges from 22 March to 25 April.
      expect(isSeasonActive('easter', DateTime(2026, 3, 22)), isTrue);
      expect(isSeasonActive('easter', DateTime(2026, 4, 25)), isTrue);
    });

    test('an unknown or missing season is never active', () {
      expect(isSeasonActive(null, DateTime(2026, 12, 24)), isFalse);
      expect(isSeasonActive('christmas', DateTime(2026, 12, 24)), isFalse,
          reason: 'a typo in pages.json must not surface a page year-round');
    });
  });

  group('category ordering', () {
    final pages = [
      const ColoringPage(
          id: 'cat', title: 'Katze', file: 'cat.svg', category: 'Tiere'),
      const ColoringPage(
          id: 'tree',
          title: 'Weihnachtsbaum',
          file: 'christmas_tree.svg',
          category: 'Jahreszeiten',
          season: 'winter'),
      const ColoringPage(
          id: 'car', title: 'Auto', file: 'car.svg', category: 'Fahrzeuge'),
    ];
    final categories = ['Tiere', 'Jahreszeiten', 'Fahrzeuge'];

    test('the seasonal category moves to the front while it is in season', () {
      expect(
        orderedCategories(categories, pages, DateTime(2026, 12, 12)),
        ['Jahreszeiten', 'Tiere', 'Fahrzeuge'],
      );
    });

    test('out of season nothing moves at all', () {
      expect(
        orderedCategories(categories, pages, DateTime(2026, 7, 12)),
        categories,
        reason: 'the tab order a child has learned must stay put',
      );
    });
  });

  group('seasonal catalog', () {
    /// The pages added in v6.9, read from the catalog rather than hardcoded
    /// so a new seasonal entry is covered the moment it is added.
    List<ColoringPage> seasonalPages() {
      final raw =
          File('assets/coloring_pages/pages.json').readAsStringSync();
      return (jsonDecode(raw) as List)
          .map((e) => ColoringPage(
                id: e['id'] as String,
                title: e['title'] as String,
                titleEn: e['titleEn'] as String?,
                file: e['file'] as String,
                category: e['category'] as String,
                categoryEn: e['categoryEn'] as String?,
                mode: e['mode'] as String?,
                season: e['season'] as String?,
              ))
          .where((p) => p.season != null)
          .toList();
    }

    test('the catalog is complete and consistent', () {
      final pages = seasonalPages();
      expect(pages, hasLength(12));
      for (final page in pages) {
        expect(File('assets/coloring_pages/${page.file}').existsSync(), isTrue,
            reason: '${page.id}: missing SVG');
        expect(page.titleEn, isNotNull, reason: '${page.id}: no English title');
        expect(page.category, 'Jahreszeiten');
        expect(kSeasonWindows.containsKey(page.season), isTrue,
            reason: '${page.id}: unknown season "${page.season}"');
      }
      // Every occasion actually has pages — a window with nothing behind it
      // would silently do nothing.
      expect(pages.map((p) => p.season).toSet(),
          kSeasonWindows.keys.toSet());
    });

    // The artwork itself (does it rasterize into fillable regions?) is
    // checked for every page in the catalog by `page_artwork_test.dart` —
    // it used to live here for the seasonal twelve only.
  });
}
