import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/models/tool.dart';
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
