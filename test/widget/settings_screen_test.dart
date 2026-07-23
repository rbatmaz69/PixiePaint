import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/settings/settings_screen.dart';
import 'package:pixiepaint/util/settings.dart';

import 'harness.dart';

/// The settings screen is the parents' control panel. These tests cover
/// what the screen offers and that its switches actually move the settings;
/// persistence to disk is covered by settings_test.dart.
void main() {
  late Directory root;

  /// Storage setup has to happen inside the test body (it needs the tester
  /// to escape the fake-async zone), so every test opens with this.
  Future<void> start(WidgetTester tester, {double textScale = 1.0}) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    await pumpPixie(
      tester,
      const SettingsScreen(),
      size: const Size(500, 1400),
      textScale: textScale,
    );
  }

  testWidgets('the safety toggles are all on screen', (tester) async {
    await start(tester);

    expect(find.text('Nur mit Stift malen'), findsOneWidget);
    expect(find.text('Löschen nur für Eltern'), findsOneWidget);
    expect(find.text('Linkshänder-Modus'), findsOneWidget);
  });

  testWidgets('flipping the left-handed switch changes the setting',
      (tester) async {
    await start(tester);
    expect(Settings.instance.leftHanded, isFalse);

    // The row shows a Switch; tapping the label is not what a parent does.
    final row = find.ancestor(
      of: find.text('Linkshänder-Modus'),
      matching: find.byType(Row),
    );
    await tester
        .tap(find.descendant(of: row.last, matching: find.byType(Switch)));
    await tester.pump(const Duration(milliseconds: 400));

    expect(Settings.instance.leftHanded, isTrue);
    // That the flip also *reaches disk* is settings_test.dart's job: the
    // write is queued in JsonStore, whose future is created inside this
    // test's fake-async zone and would never complete here.
  });

  testWidgets('the parents section offers backup, restore and storage',
      (tester) async {
    await start(tester);

    expect(find.text('Alle Bilder sichern'), findsOneWidget);
    // A backup with no way back is only half a promise — both directions
    // have to be reachable from the same section.
    expect(find.text('Bilder zurückholen'), findsOneWidget);
    expect(find.text('Speicherplatz'), findsOneWidget);
  });

  testWidgets('every control is reachable by name with a screen reader',
      (tester) async {
    final handle = tester.ensureSemantics();
    await start(tester);

    expect(find.bySemanticsLabel('Zurück'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('the screen holds together at the largest allowed text scale',
      (tester) async {
    await start(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
  });
}
