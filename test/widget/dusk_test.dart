import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_screen.dart';
import 'package:pixiepaint/settings/settings_screen.dart';
import 'package:pixiepaint/ui/app_theme.dart';
import 'package:pixiepaint/ui/pixie_palette.dart';
import 'package:pixiepaint/ui/pixie_surfaces.dart';
import 'package:pixiepaint/util/settings.dart';

import 'harness.dart';

/// The evening mode, and the one promise it must not break.
///
/// It darkens the *ground*. The white sheet a child paints on is picture,
/// not surface: every export is laid on white, the sixty-eight line drawings
/// are black, and a gallery thumbnail is a white rectangle. A dark canvas
/// would mean painting yellow on navy and sharing yellow on white.
void main() {
  late Directory root;

  testWidgets('the backdrop follows the mode', (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));

    late PixieSurfaces day;
    late PixieSurfaces dusk;
    await pumpPixie(
      tester,
      Builder(builder: (context) {
        day = context.surfaces;
        return const SizedBox();
      }),
    );
    await pumpPixie(
      tester,
      Builder(builder: (context) {
        dusk = context.surfaces;
        return const SizedBox();
      }),
      brightness: Brightness.dark,
    );
    // MaterialApp cross-fades a theme change over a few hundred
    // milliseconds, so the first frame after the switch is still mostly
    // daytime — which is a nice thing for a child to see and a trap for a
    // test that reads the value immediately.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    expect(day.homeBg.colors.first, PixiePalette.paper);
    expect(dusk.homeBg.colors.first, PixiePalette.dusk);
    expect(day.onGround, PixiePalette.ink);
    expect(dusk.onGround, PixiePalette.chalk);
    expect(dusk.blobAlpha, lessThan(day.blobAlpha),
        reason: 'bright colour on a dark ground reads as a spill');
  });

  testWidgets('a widget without the app theme still gets a daytime backdrop',
      (tester) async {
    // The fallback exists so a bare pump cannot bring a screen down. A bang
    // here would have taken out every widget test that skips the theme.
    late PixieSurfaces seen;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        seen = context.surfaces;
        return const SizedBox();
      }),
    ));
    expect(seen.onGround, PixiePalette.ink);
  });

  testWidgets('the paper stays white in the evening', (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));

    await tester.runAsync(() async {
      await pumpPixie(tester, const CanvasScreen(),
          size: const Size(390, 780), brightness: Brightness.dark);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // The sheet is the picture, and a picture is exported on white — so it
    // must be white here whatever the mode says.
    final paper = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.borderRadius == BorderRadius.circular(PixieTokens.rTile))
        .toList();
    expect(paper, isNotEmpty, reason: 'the paper sheet should be on screen');
    expect(paper.first.color, Colors.white);
  });

  testWidgets('a parent can pick the evening mode', (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));
    await pumpPixie(tester, const SettingsScreen(),
        size: const Size(500, 1400));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(Settings.instance.themeModeIndex, 0);

    await tester.tap(find.text('Aussehen'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await tester.tap(find.text('Abendmodus'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    expect(Settings.instance.themeModeIndex, 2);
    expect(Settings.instance.themeMode, ThemeMode.dark);
  });

  testWidgets('both themes build without a missing extension', (tester) async {
    for (final b in Brightness.values) {
      final theme = buildPixieTheme(brightness: b);
      expect(theme.extension<PixieSurfaces>(), isNotNull,
          reason: 'every screen reads the backdrop from here');
    }
  });
}
