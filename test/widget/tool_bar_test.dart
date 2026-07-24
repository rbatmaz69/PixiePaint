import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/ui/pop_in.dart';
import 'package:pixiepaint/widgets/color_palette.dart';
import 'package:pixiepaint/widgets/tool_bar.dart';

import 'harness.dart';

/// The toolbar is the app's densest cluster of controls and the one place
/// where a screen-reader user has to know not just *what* a button is but
/// *which one is currently on*.
void main() {
  late CanvasController controller;

  setUp(() => controller =
      CanvasController(canvasWidth: 2048, canvasHeight: 1536));
  tearDown(() => controller.dispose());

  /// The rail and the fixed action cluster, side by side — the way every
  /// screen in the app puts them together since v8.0.
  Future<void> pumpToolBar(WidgetTester tester, {double textScale = 1.0}) =>
      pumpPixie(
        tester,
        Scaffold(
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ToolBarRail(controller: controller),
                ToolActionCluster(controller: controller),
              ],
            ),
          ),
        ),
        size: const Size(900, 1800),
        textScale: textScale,
      );

  testWidgets('every tool button announces itself to a screen reader',
      (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    final handle = tester.ensureSemantics();

    await pumpToolBar(tester);

    // Painting with a screen reader on means finding the brush by name.
    expect(find.bySemanticsLabel('Pinsel'), findsOneWidget);
    expect(find.bySemanticsLabel('Radierer'), findsOneWidget);
    expect(find.bySemanticsLabel('Füllen'), findsOneWidget);
    expect(find.bySemanticsLabel('Rückgängig'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('the active tool is announced as selected, not just present',
      (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    final handle = tester.ensureSemantics();

    await pumpToolBar(tester);
    controller.selectTool(ToolKind.eraser);
    await tester.pumpAndSettle();

    final eraser = tester.getSemantics(find.bySemanticsLabel('Radierer'));
    expect(eraser.flagsCollection.isSelected, Tristate.isTrue,
        reason: 'a screen reader must reveal which tool is currently on');
    expect(eraser.flagsCollection.isButton, isTrue);

    handle.dispose();
  });

  testWidgets('tapping a tool selects it on the controller', (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));

    await pumpToolBar(tester);
    expect(controller.tool, isNot(ToolKind.eraser));

    await tester.tap(find.bySemanticsLabel('Radierer'));
    await tester.pumpAndSettle();

    expect(controller.tool, ToolKind.eraser);
  });

  testWidgets('undo is announced as disabled while there is nothing to undo',
      (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    final handle = tester.ensureSemantics();

    await pumpToolBar(tester);

    final undo = tester.getSemantics(find.bySemanticsLabel('Rückgängig'));
    expect(undo.flagsCollection.isEnabled, Tristate.isFalse);

    handle.dispose();
  });

  testWidgets('colors have spoken names instead of sixteen identical buttons',
      (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    final handle = tester.ensureSemantics();

    await pumpPixie(
      tester,
      Scaffold(body: Center(child: ColorPalette(controller: controller))),
      size: const Size(900, 300),
    );

    expect(find.bySemanticsLabel('Rot'), findsOneWidget);
    expect(find.bySemanticsLabel('Blau'), findsOneWidget);
    expect(find.bySemanticsLabel('Schwarz'), findsOneWidget);
    expect(find.bySemanticsLabel('Mehr Farben'), findsOneWidget);

    handle.dispose();
  });

  group('simple mode', () {
    Future<void> pumpSimple(WidgetTester tester) => pumpPixie(
          tester,
          Scaffold(
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ToolBarRail(controller: controller, simple: true),
                  ToolActionCluster(controller: controller),
                ],
              ),
            ),
          ),
          size: const Size(900, 1800),
        );

    testWidgets('shows four tools instead of fourteen', (tester) async {
      final root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(root));
      final handle = tester.ensureSemantics();

      await pumpSimple(tester);

      for (final label in ['Pinsel', 'Füllen', 'Sticker', 'Radierer']) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      for (final label in ['Regenbogen', 'Glitzer', 'Neon', 'Pipette',
        'Formen', 'Zauber-Spiegel']) {
        expect(find.bySemanticsLabel(label), findsNothing, reason: label);
      }

      // What must not disappear: undoing a mistake, and thick vs. thin.
      expect(find.bySemanticsLabel('Rückgängig'), findsOneWidget);
      expect(find.bySemanticsLabel('Pinselgröße'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the bucket paints straight away, with no sheet in the way',
        (tester) async {
      final root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(root));
      final handle = tester.ensureSemantics();

      await pumpSimple(tester);
      await tester.tap(find.bySemanticsLabel('Füllen'));
      await tester.pumpAndSettle();

      expect(controller.tool, ToolKind.fill);
      // The pattern sheet lists the eight fills by name; none of them may
      // stand between a three-year-old and a tap that paints.
      expect(find.text('Punkte'), findsNothing,
          reason: 'a three-year-old should get paint from one tap');

      handle.dispose();
    });

    testWidgets('its buttons are bigger than the full toolbar\'s',
        (tester) async {
      final root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(root));
      final handle = tester.ensureSemantics();

      await pumpToolBar(tester);
      final full = tester.getSize(find.bySemanticsLabel('Pinsel'));
      await pumpSimple(tester);
      // The button size is animated, and pumping the second tree reuses the
      // first one's elements — without letting the tween finish, this would
      // measure the old size and pass for the wrong reason.
      await tester.pumpAndSettle();
      final simple = tester.getSize(find.bySemanticsLabel('Pinsel'));

      expect(simple.width, greaterThan(full.width));

      handle.dispose();
    });
  });

  // The picked-up tool hops (v8.4). The one being put down must not — a
  // double motion on the tool you just left reads as an error, not as an
  // answer. Both buttons are Pulses; only the new one may be running.
  testWidgets('picking a tool up hops, putting one down stays quiet',
      (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    final handle = tester.ensureSemantics();

    await pumpToolBar(tester);
    await tester.pumpAndSettle();

    // The emoji's Pulse is the first one inside a tool button; brush, fill
    // and shape carry a second one on their color badge. Its own
    // ScaleTransition is likewise the outermost of several — AnimatedScale
    // builds one too.
    ScaleTransition pulseOf(String label) => tester.widget<ScaleTransition>(
          find
              .descendant(
                of: find
                    .descendant(
                      of: find.bySemanticsLabel(label),
                      matching: find.byType(Pulse),
                    )
                    .first,
                matching: find.byType(ScaleTransition),
              )
              .first,
        );

    controller.selectTool(ToolKind.brush);
    await tester.pumpAndSettle();

    // Switch away: the marker is picked up, the brush is put down.
    controller.selectTool(ToolKind.marker);
    // Two pumps on purpose: the first is the rebuild that starts the pulse,
    // the second lets it run. Advancing the clock in the first would sample
    // the controller at zero and pass for the wrong reason.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(pulseOf('Filzstift').scale.value, greaterThan(1.0),
        reason: 'das aufgenommene Werkzeug hat nicht geantwortet');
    expect(pulseOf('Pinsel').scale.value, 1.0,
        reason: 'das abgelegte Werkzeug hat mitgehüpft');

    handle.dispose();
  });

  testWidgets('the toolbar survives the largest text scale the app allows',
      (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));

    // 2.0 is what a phone with the largest accessibility font asks for; the
    // app clamps it to 1.3, and nothing may overflow at that size.
    await pumpToolBar(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
  });
}
