import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/almost_done.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/canvas/canvas_screen.dart';

import 'harness.dart';

/// The ✨ hint: what it shows, when it disappears, and who never sees it.
void main() {
  late CanvasController controller;

  setUp(() {
    controller = CanvasController(canvasWidth: 200, canvasHeight: 150);
  });

  tearDown(() => controller.dispose());

  Future<void> pumpOverlay(WidgetTester tester,
      {bool reduceMotion = false}) async {
    await pumpPixie(
      tester,
      Center(
        child: SizedBox(
          width: 200,
          height: 150,
          child: AlmostDoneOverlay(controller: controller),
        ),
      ),
      reduceMotion: reduceMotion,
    );
  }

  final marks = find.descendant(
    of: find.byType(AlmostDoneOverlay),
    matching: find.byType(CustomPaint),
  );

  testWidgets('nothing is drawn until the button asks', (tester) async {
    await pumpOverlay(tester);

    expect(marks, findsNothing);
  });

  testWidgets('the marks appear and clear themselves again', (tester) async {
    await pumpOverlay(tester);

    controller.hintSpots.value = const [Offset(40, 40), Offset(120, 90)];
    await tester.pump();
    expect(marks, findsOneWidget);

    // Still there while the hint is running...
    await tester.pump(kHintDwell ~/ 2);
    expect(marks, findsOneWidget);

    // ...and gone on its own afterwards, without anyone tidying up.
    await tester.pump(kHintDwell);
    expect(marks, findsNothing);
  });

  testWidgets('reduce motion keeps the hint, only the movement goes',
      (tester) async {
    // The wrong half to remove would be the information: a child who asked
    // what is missing still has to be told.
    await pumpOverlay(tester, reduceMotion: true);

    controller.hintSpots.value = const [Offset(40, 40)];
    await tester.pump();

    expect(marks, findsOneWidget);
    await tester.pump(kHintDwell ~/ 2);
    expect(marks, findsOneWidget);
  });

  testWidgets('clearing the spots takes the marks away at once',
      (tester) async {
    await pumpOverlay(tester);
    controller.hintSpots.value = const [Offset(40, 40)];
    await tester.pump();
    expect(marks, findsOneWidget);

    controller.hintSpots.value = const [];
    await tester.pump();

    expect(marks, findsNothing);
  });

  testWidgets('free drawing has no ✨ button — there is nothing to measure',
      (tester) async {
    // No line art means no enclosed areas, so "what is still missing?" has
    // no answer. The button is not shown rather than shown and useless.
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));
    final handle = tester.ensureSemantics();

    await pumpPixie(tester, const CanvasScreen(), size: const Size(360, 640));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.bySemanticsLabel('Was fehlt noch?'), findsNothing);
    // Counter-proof that the canvas really is up and its controls are there.
    expect(find.bySemanticsLabel('Zurück'), findsWidgets);

    handle.dispose();
  });
}
