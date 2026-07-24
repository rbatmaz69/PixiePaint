import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the nine translations against the two failure modes that only
/// show up at runtime — as a German sentence in the middle of a Polish
/// screen, or as a crash when a placeholder is missing.
///
/// German is the template (`l10n.yaml`) and therefore the reference.
void main() {
  const languages = ['en', 'es', 'fr', 'it', 'nl', 'pl', 'pt', 'tr'];

  Map<String, dynamic> arb(String code) => jsonDecode(
        File('lib/l10n/app_$code.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

  final template = arb('de');
  final templateKeys =
      template.keys.where((k) => !k.startsWith('@')).toSet();

  /// Placeholder names in a message, minus the ICU plural keywords.
  Set<String> placeholdersOf(String message) => RegExp(r'\{(\w+)[,}]')
      .allMatches(message)
      .map((m) => m.group(1)!)
      .where((n) => !const {
            'plural',
            'zero',
            'one',
            'two',
            'few',
            'many',
            'other',
          }.contains(n))
      .toSet();

  test('the template itself is sane', () {
    // No exact count on purpose: every new feature adds keys, and a test
    // that has to be edited for each one gets edited without thinking. What
    // must not happen is the template silently shrinking.
    expect(templateKeys.length, greaterThan(200));
    expect(template['@@locale'], 'de');
  });

  for (final code in languages) {
    group(code, () {
      test('has every key the template has, and no extras', () {
        final keys = arb(code).keys.where((k) => !k.startsWith('@')).toSet();

        expect(keys.difference(templateKeys), isEmpty,
            reason: 'keys no longer used anywhere');
        expect(templateKeys.difference(keys), isEmpty,
            reason: 'a missing key surfaces as German text mid-screen');
      });

      test('declares the same locale as its filename', () {
        expect(arb(code)['@@locale'], code);
      });

      test('uses exactly the placeholders the template uses', () {
        final table = arb(code);
        for (final key in templateKeys) {
          final expected = placeholdersOf(template[key] as String);
          final actual = placeholdersOf(table[key] as String);
          expect(actual, expected,
              reason: '$code.$key: a dropped placeholder means the number '
                  'never reaches the sentence');
        }
      });

      test('leaves no message empty', () {
        final table = arb(code);
        for (final key in templateKeys) {
          expect((table[key] as String).trim(), isNotEmpty,
              reason: '$code.$key is blank');
        }
      });
    });
  }

  test('polish spells out the plural forms its grammar needs', () {
    // Polish distinguishes 1 / 2-4 / 5+ — with only one/other, "5 obrazek"
    // comes out where "5 obrazków" belongs.
    final pl = arb('pl');
    final pluralKeys = templateKeys
        .where((k) => (template[k] as String).contains('plural'))
        .toList();

    expect(pluralKeys, hasLength(11));
    for (final key in pluralKeys) {
      final message = pl[key] as String;
      expect(message, contains('few{'), reason: '$key has no "few" form');
      expect(message, contains('many{'), reason: '$key has no "many" form');
    }
  });

  test('every language keeps the plural messages plural', () {
    final pluralKeys = templateKeys
        .where((k) => (template[k] as String).contains('plural'))
        .toList();

    for (final code in languages) {
      final table = arb(code);
      for (final key in pluralKeys) {
        expect(table[key], contains('plural,'),
            reason: '$code.$key lost its plural block — the count would be '
                'printed into a sentence written for one item');
      }
    }
  });
}
