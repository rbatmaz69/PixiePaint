import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/profiles.dart';
import 'package:pixiepaint/widgets/profile_sheet.dart';

import 'harness.dart';

/// Switching kids and — the part that matters — removing one. A removal
/// takes a whole child's pictures with it if the parent says so, which
/// makes it the most destructive button in the app.
///
/// What lands on disk is covered by profile_store_test.dart; this checks
/// that the screen puts the right questions in front of that.
void main() {
  late Directory root;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> start(WidgetTester tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    await pumpPixie(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showProfileSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      size: const Size(500, 900),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  /// Answers the parental gate correctly — it guards the manage sheet.
  Future<void> passGate(WidgetTester tester) async {
    final question = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .firstWhere((s) => s.contains('×'));
    final parts = question.split('×');
    final a = int.parse(parts[0].trim());
    final b = int.parse(parts[1].replaceAll('=', '').replaceAll('?', '').trim());
    await tester.enterText(find.byType(TextField), '${a * b}');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
  }

  Future<void> openManage(WidgetTester tester) async {
    await tester.tap(find.text('Verwalten (für Eltern)'));
    await settle(tester);
    await passGate(tester);
  }

  testWidgets('the sheet shows the kids who paint on this device',
      (tester) async {
    await start(tester);
    await tester.runAsync(
        () => ProfileStore.instance.addProfile(name: 'Mia', emoji: '🐸'));
    await settle(tester);

    expect(find.text('Mia'), findsOneWidget);
    expect(ProfileStore.instance.profiles, hasLength(2));
  });

  testWidgets('tapping a kid makes them the active one', (tester) async {
    await start(tester);
    final primaryId = ProfileStore.instance.primary.id;
    await tester.runAsync(
        () => ProfileStore.instance.addProfile(name: 'Mia', emoji: '🐸'));
    await settle(tester);
    // Adding already switches to the new kid.
    expect(ProfileStore.instance.active.name, 'Mia');

    await tester.tap(find.text('Ich'));
    await settle(tester);

    expect(ProfileStore.instance.active.id, primaryId);
  });

  testWidgets('removing a kid asks what happens to their pictures',
      (tester) async {
    await start(tester);
    await tester.runAsync(
        () => ProfileStore.instance.addProfile(name: 'Mia', emoji: '🐸'));
    await settle(tester);
    await openManage(tester);

    // The manage list offers a remove per kid; the primary must not have one.
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).last);
    await settle(tester);

    expect(find.textContaining('Mia entfernen?'), findsOneWidget);
    // Three answers, and the destructive one is not the eye-catcher.
    expect(find.text('Bilder behalten'), findsOneWidget);
    expect(find.text('Bilder auch löschen'), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
  });

  testWidgets('cancelling the removal keeps the kid', (tester) async {
    await start(tester);
    await tester.runAsync(
        () => ProfileStore.instance.addProfile(name: 'Mia', emoji: '🐸'));
    await settle(tester);
    await openManage(tester);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).last);
    await settle(tester);
    await tester.tap(find.text('Abbrechen'));
    await settle(tester);

    expect(ProfileStore.instance.profiles, hasLength(2),
        reason: 'backing out of a removal must remove nothing');
    expect(ProfileStore.instance.profiles.map((p) => p.name), contains('Mia'));
  });

  testWidgets('the main profile has no remove button at all', (tester) async {
    await start(tester);
    await openManage(tester);

    // Only the primary exists, so there is nothing removable on screen.
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing,
        reason: 'the primary owns the legacy pictures and must always exist');
  });

  testWidgets('the manage list is behind the parental gate', (tester) async {
    await start(tester);

    await tester.tap(find.text('Verwalten (für Eltern)'));
    await settle(tester);

    expect(find.text('Frag deine Eltern!'), findsOneWidget);
    expect(find.text('Kind hinzufügen'), findsNothing,
        reason: 'a child must not reach profile management on their own');
  });
}
