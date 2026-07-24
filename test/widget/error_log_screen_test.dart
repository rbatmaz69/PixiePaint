import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/settings/error_log_screen.dart';
import 'package:pixiepaint/settings/settings_screen.dart';
import 'package:pixiepaint/util/error_log.dart';

import 'harness.dart';

/// The problem report is a parents' screen with a button that sends a file
/// off the device — so the tests here are about the gate standing in front of
/// both doors, and about the screen staying sane when the log is empty.
void main() {
  late Directory root;
  final log = ErrorLog.instance;

  /// Advances past the entrance animations without settling — the gate's
  /// autofocused field blinks forever, so `pumpAndSettle` would time out.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> setUpLog(WidgetTester tester, {int entries = 0}) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    await tester.runAsync(() async {
      log.resetForTest();
      await log.initIn(root);
      for (var i = 0; i < entries; i++) {
        log.record(StateError('Testfehler $i'), StackTrace.current,
            origin: ErrorOrigin.flutter);
      }
      await log.flush();
    });
    addTearDown(log.resetForTest);
  }

  testWidgets('an empty log says so instead of showing an empty list',
      (tester) async {
    await setUpLog(tester);
    await pumpPixie(tester, const ErrorLogScreen(), size: const Size(420, 860));
    await settle(tester);

    expect(find.text('Alles in Ordnung – nichts zu berichten.'), findsOneWidget);
    expect(find.text('Keine Einträge'), findsOneWidget);
    // Nothing to share and nothing to clear, so neither is offered.
    expect(find.text('Bericht teilen'), findsNothing);
    expect(find.text('Liste leeren'), findsNothing);
  });

  testWidgets('recorded errors are listed newest first', (tester) async {
    await setUpLog(tester, entries: 3);
    await pumpPixie(tester, const ErrorLogScreen(), size: const Size(420, 860));
    await settle(tester);

    expect(find.text('3 Einträge'), findsOneWidget);
    expect(find.textContaining('Testfehler 2'), findsOneWidget);
    expect(find.textContaining('Testfehler 0'), findsOneWidget);
    expect(find.text('Bericht teilen'), findsOneWidget);
  });

  testWidgets('a repeated error is shown as a count, not as many rows',
      (tester) async {
    await setUpLog(tester);
    await tester.runAsync(() async {
      for (var i = 0; i < 5; i++) {
        log.record(StateError('immer wieder'), null,
            origin: ErrorOrigin.flutter);
      }
      await log.flush();
    });

    await pumpPixie(tester, const ErrorLogScreen(), size: const Size(420, 860));
    await settle(tester);

    expect(find.text('1 Eintrag'), findsOneWidget);
    expect(find.text('5×'), findsOneWidget);
  });

  testWidgets('clearing asks first, and "keep" keeps everything',
      (tester) async {
    await setUpLog(tester, entries: 2);
    await pumpPixie(tester, const ErrorLogScreen(), size: const Size(420, 860));
    await settle(tester);

    await tester.tap(find.text('Liste leeren'));
    await settle(tester);
    expect(find.text('Alle Einträge löschen?'), findsOneWidget);

    await tester.tap(find.text('Doch behalten'));
    await settle(tester);
    expect(log.count, 2, reason: '"keep" must not delete anything');

    // ...and confirming does empty it. Deliberately no `flush()` here: the
    // write was queued from inside the fake-async zone, so awaiting it would
    // wait for a future only pumping can advance — the deadlock that hangs a
    // widget test instead of failing it.
    await tester.tap(find.text('Liste leeren'));
    await settle(tester);
    await tester.tap(find.text('Löschen'));
    await settle(tester);

    expect(log.isEmpty, isTrue);
    expect(find.text('Alles in Ordnung – nichts zu berichten.'), findsOneWidget);
  });

  testWidgets('sharing the report asks the parental question first',
      (tester) async {
    await setUpLog(tester, entries: 1);
    await pumpPixie(tester, const ErrorLogScreen(), size: const Size(420, 860));
    await settle(tester);

    await tester.tap(find.text('Bericht teilen'));
    await settle(tester);

    // The gate, not the share sheet: the report leaves the device.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('×'), findsWidgets);

    await tester.tap(find.text('Abbrechen'));
    await settle(tester);
    expect(log.count, 1);
  });

  testWidgets('the settings screen only opens the report behind the gate',
      (tester) async {
    await setUpLog(tester, entries: 1);
    await pumpPixie(tester, const SettingsScreen(), size: const Size(420, 900));
    await settle(tester);

    await tester.dragUntilVisible(
      find.text('Problembericht'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    await settle(tester);
    await tester.tap(find.text('Problembericht'));
    await settle(tester);

    expect(find.byType(TextField), findsOneWidget,
        reason: 'the gate must stand in front of the parents\' screen');
    expect(find.byType(ErrorLogScreen), findsNothing);
  });
}
