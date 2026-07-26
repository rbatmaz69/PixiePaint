import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/gallery/home_screen.dart';
import 'package:pixiepaint/gallery/page_picker_screen.dart';
import 'package:pixiepaint/gallery/welcome_screen.dart';
import 'package:pixiepaint/util/settings.dart';

import 'harness.dart';

/// The one-time welcome. The rule it has to keep: a child who wants to
/// paint right now must be able to, so "skip" is on every card from the
/// first one, and neither route out may leave the welcome coming back.
void main() {
  late Directory root;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> start(WidgetTester tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));
    await pumpPixie(tester, const WelcomeScreen(),
        size: const Size(420, 860));
    await settle(tester);
  }

  testWidgets('opens on the greeting', (tester) async {
    await start(tester);

    expect(find.text('Hallo, ich bin Pixie!'), findsOneWidget);
    expect(Settings.instance.welcomeSeen, isFalse);
  });

  testWidgets('skip is offered on the very first card', (tester) async {
    await start(tester);

    expect(find.text('Überspringen'), findsOneWidget,
        reason: 'a child who wants to paint now is allowed to');
  });

  testWidgets('walking through reaches the parents card last',
      (tester) async {
    await start(tester);

    await tester.tap(find.text('Weiter'));
    await settle(tester);
    expect(find.text('Such dir ein Bild aus'), findsOneWidget);

    await tester.tap(find.text('Weiter'));
    await settle(tester);
    expect(find.text('Für Eltern'), findsOneWidget);
    // The last card offers to start rather than to continue.
    expect(find.text('Los malen!'), findsOneWidget);
    expect(find.text('Weiter'), findsNothing);
  });

  testWidgets('the parents card names what matters to a parent',
      (tester) async {
    await start(tester);
    await tester.tap(find.text('Weiter'));
    await settle(tester);
    await tester.tap(find.text('Weiter'));
    await settle(tester);

    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .join(' ');
    expect(text, contains('keine Werbung'));
    expect(text, contains('keine Käufe'));
    expect(text, contains('Rechenaufgabe'),
        reason: 'the parental gate is the thing a parent needs to know about');
  });

  testWidgets('skipping records that the welcome has run', (tester) async {
    await start(tester);

    await tester.tap(find.text('Überspringen'));
    await settle(tester);

    expect(Settings.instance.welcomeSeen, isTrue,
        reason: 'skipping must not bring the welcome back tomorrow');
  });

  testWidgets('finishing records it too', (tester) async {
    await start(tester);
    await tester.tap(find.text('Weiter'));
    await settle(tester);
    await tester.tap(find.text('Weiter'));
    await settle(tester);

    await tester.tap(find.text('Los malen!'));
    await settle(tester);

    expect(Settings.instance.welcomeSeen, isTrue);
  });

  // The welcome used to *replace* itself with the picture picker, which made
  // the picker the root: its back arrow popped the last route and left an
  // empty navigator, and the gallery, the rewards, the profile, the music
  // and "carry on painting" — all of which live on the home screen — were
  // unreachable for the whole first session.
  testWidgets('leaves a home screen behind the pictures', (tester) async {
    await start(tester);

    await tester.tap(find.text('Überspringen'));
    await settle(tester);

    expect(find.byType(PagePickerScreen), findsOneWidget,
        reason: 'the first thing a child sees is still pictures');

    // Back out of the picker: there has to be something under it.
    await tester.tap(find.bySemanticsLabel('Zurück').first);
    await settle(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing,
        reason: 'and the welcome does not come back');
  });

  testWidgets('it survives the largest text scale the app allows',
      (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));
    await pumpPixie(tester, const WelcomeScreen(),
        size: const Size(420, 860), textScale: 2.0);
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
