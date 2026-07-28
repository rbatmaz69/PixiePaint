import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/util/color_utils.dart';
import 'package:pixiepaint/widgets/color_picker_sheet.dart';

import 'harness.dart';

/// The mixing pot sits inside the sheet whose first job is handing over a
/// colour. So the thing worth testing is not the arithmetic ([mixPaint] has
/// its own tests) but the flow around it: that a plain tap still picks a
/// colour and closes, and that mixing takes exactly the taps a child is
/// shown.
void main() {
  late Directory root;
  late CanvasController controller;

  Future<void> openSheet(WidgetTester tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));
    controller = CanvasController(canvasWidth: 64, canvasHeight: 48);
    addTearDown(controller.dispose);

    await pumpPixie(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showColorPickerSheet(context, controller),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      size: const Size(420, 900),
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  /// The two empty bowls, in order.
  Finder slots() => find.bySemanticsLabel('Farbe wählen');

  testWidgets('a plain tap on a colour still picks it and closes',
      (tester) async {
    await openSheet(tester);
    final before = controller.color;

    await tester.tap(find.bySemanticsLabel('Blau').first);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    expect(controller.color, isNot(before));
    expect(slots(), findsNothing, reason: 'the sheet closed');
  });

  testWidgets('two taps fill both bowls and the result can be taken',
      (tester) async {
    await openSheet(tester);

    // Tapping the first bowl arms it; the sheet stays open and the next
    // colour goes into the pot instead of onto the brush.
    await tester.tap(slots().first);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.bySemanticsLabel('Blau').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(slots(), findsOneWidget, reason: 'one bowl still empty');
    expect(controller.color, isNot(const Color(0xFF1E88E5)),
        reason: 'a tap into the pot must not also pick the colour');

    // The second bowl was armed automatically — one thought, two taps.
    await tester.tap(find.bySemanticsLabel('Gelb').first);
    // The sheet grows when the answer appears, so it re-lays out; tapping
    // before that has settled taps where the button no longer is.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(slots(), findsNothing, reason: 'both bowls hold a colour now');

    final take = find.bySemanticsLabel(RegExp('Nehmen!'));
    expect(take, findsOneWidget);
    await tester.tap(take);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    // Blue and yellow: the picked colour is the green the paint box gives.
    final hue = HSLColor.fromColor(controller.color).hue;
    expect(hue, inInclusiveRange(75, 165));
  });

  testWidgets('the broom empties the pot again', (tester) async {
    await openSheet(tester);
    await tester.tap(slots().first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.bySemanticsLabel('Rot').first);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.bySemanticsLabel('Topf leeren'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(slots(), findsNWidgets(2));
  });
}
