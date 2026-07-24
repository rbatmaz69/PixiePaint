import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/models/coloring_page.dart';
import 'package:pixiepaint/models/daily_task.dart';
import 'package:pixiepaint/models/localized_name.dart';
import 'package:pixiepaint/models/scene.dart';

/// The content names, in all nine languages.
///
/// Until v7.6 the model knew German and English and nothing else: the whole
/// interface was translated, and a Turkish child read "Schmetterling" under
/// the butterfly. `test/l10n_test.dart` could never have caught it — these
/// names are content, not ARB keys, so they need their own guard.
void main() {
  const languages = ['es', 'fr', 'it', 'nl', 'pl', 'pt', 'tr'];
  const allLanguages = ['de', 'en', ...languages];

  List<Map<String, dynamic>> read(String path) =>
      (jsonDecode(File(path).readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();

  group('coloring pages', () {
    final entries = read('assets/coloring_pages/pages.json');

    test('every picture is named in every language', () {
      for (final entry in entries) {
        final names = namesFromJson(entry['titles']);
        expect(names, isNotNull,
            reason: '${entry['id']}: no "titles" map at all');
        for (final code in languages) {
          expect(names![code]?.trim() ?? '', isNotEmpty,
              reason: '${entry['id']}: missing $code title');
        }
      }
    });

    test('titleFor returns a different word per language where it should', () {
      final cat = ColoringPage(
        id: 'cat',
        title: 'Katze',
        titleEn: 'Cat',
        titles: namesFromJson(
            entries.firstWhere((e) => e['id'] == 'cat')['titles']),
        file: 'cat.svg',
        category: 'Tiere',
        categoryEn: 'Animals',
      );
      expect(cat.titleFor('de'), 'Katze');
      expect(cat.titleFor('en'), 'Cat');
      expect(cat.titleFor('tr'), 'Kedi');
      expect(cat.titleFor('pl'), 'Kot');
      // An unsupported language falls back to English, not to a blank.
      expect(cat.titleFor('sv'), 'Cat');
    });

    test('every category is named in every language', () {
      final categories = entries.map((e) => e['category'] as String).toSet();
      for (final category in categories) {
        final names = kCategoryNames[category];
        expect(names, isNotNull, reason: '$category: not in kCategoryNames');
        for (final code in languages) {
          expect(names![code]?.trim() ?? '', isNotEmpty,
              reason: '$category: missing $code name');
        }
      }
      // No leftovers either: a category that no page uses any more is dead
      // weight that still shows up in a review of the picker.
      expect(kCategoryNames.keys.toSet(), categories);
    });

    test('categoryFor uses the shared table', () {
      const page = ColoringPage(
          id: 'cow',
          title: 'Kuh',
          file: 'cow.svg',
          category: 'Bauernhof',
          categoryEn: 'Farm');
      expect(page.categoryFor('de'), 'Bauernhof');
      expect(page.categoryFor('en'), 'Farm');
      expect(page.categoryFor('fr'), 'Ferme');
      expect(page.categoryFor('pl'), 'Gospodarstwo');
    });
  });

  group('scenes', () {
    final entries = read('assets/scenes/scenes.json');

    test('every scene is named in every language', () {
      for (final entry in entries) {
        final names = namesFromJson(entry['titles']);
        expect(names, isNotNull, reason: '${entry['id']}: no "titles" map');
        for (final code in languages) {
          expect(names![code]?.trim() ?? '', isNotEmpty,
              reason: '${entry['id']}: missing $code title');
        }
        expect(File('assets/scenes/${entry['file']}').existsSync(), isTrue,
            reason: '${entry['id']}: missing SVG');
      }
      expect(entries, hasLength(8));
    });

    test('titleFor picks the translation', () {
      final entry = entries.firstWhere((e) => e['id'] == 'circus');
      final scene = Scene(
        id: 'circus',
        title: entry['title'] as String,
        titleEn: entry['titleEn'] as String?,
        titles: namesFromJson(entry['titles']),
        file: entry['file'] as String,
      );
      expect(scene.titleFor('de'), 'Zirkus');
      expect(scene.titleFor('pl'), 'Cyrk');
    });
  });

  group('daily tasks', () {
    test('every prompt is written in every language', () {
      for (final task in kDailyTasks) {
        expect(task.titles, isNotNull, reason: '${task.id}: no titles map');
        for (final code in languages) {
          expect(task.titles![code]?.trim() ?? '', isNotEmpty,
              reason: '${task.id}: missing $code prompt');
        }
      }
    });

    test('the list is long enough and free of duplicates', () {
      // Addressed cyclically by date, so a duplicate id would break the
      // "done today" bookkeeping, and a short list repeats too soon.
      expect(kDailyTasks.length, greaterThanOrEqualTo(45));
      expect(kDailyTasks.map((t) => t.id).toSet(),
          hasLength(kDailyTasks.length));
    });

    test('a prompt reads in the language it is asked for', () {
      for (final code in allLanguages) {
        for (final task in kDailyTasks) {
          expect(task.titleFor(code).trim(), isNotEmpty);
        }
      }
    });
  });
}
