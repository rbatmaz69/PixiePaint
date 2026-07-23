import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/widgets/parental_gate.dart';

import 'harness.dart';

/// The gate is the app's only real boundary: everything that leaves the
/// device or destroys a picture sits behind it. These tests are about that
/// boundary holding, not about the arithmetic.
void main() {
  late Future<bool> answer;

  /// Advances past the dialog's entrance animation.
  ///
  /// Deliberately not `pumpAndSettle`: the gate autofocuses its answer
  /// field, and a focused [TextField]'s blinking cursor schedules frames
  /// forever, so settling never happens.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  /// Puts a button on screen that opens the gate, taps it, and leaves the
  /// gate's future in [answer] for the test to await *after* it is done
  /// driving the tester — awaiting it earlier would deadlock, since the
  /// future only completes once the dialog is dismissed.
  Future<void> openGate(WidgetTester tester) async {
    await pumpPixie(
      tester,
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => answer = ParentalGate.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  /// Reads the two factors straight off the dialog, so the test solves the
  /// same problem a parent does instead of reaching into private state.
  int expectedAnswer(WidgetTester tester) {
    final question = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .firstWhere((s) => s.contains('×'));
    final parts = question.split('×');
    final a = int.parse(parts[0].trim());
    final b = int.parse(parts[1].replaceAll('=', '').replaceAll('?', '').trim());
    return a * b;
  }

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
  }

  testWidgets('the right answer opens the gate', (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));

    await openGate(tester);
    await submit(tester, '${expectedAnswer(tester)}');

    expect(await answer, isTrue);
  });

  testWidgets('a wrong answer keeps the gate shut', (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));

    await openGate(tester);
    await submit(tester, '1');

    // Still open, still asking — nobody has been let through.
    expect(find.byType(TextField), findsOneWidget);

    await submit(tester, '${expectedAnswer(tester)}');
    expect(await answer, isTrue);
  });

  testWidgets('three wrong answers give up rather than let anyone in',
      (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));

    await openGate(tester);
    for (var i = 0; i < 3; i++) {
      await submit(tester, '1');
    }

    expect(await answer, isFalse);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('cancelling reports a refusal, never a pass', (tester) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));

    await openGate(tester);
    await tester.tap(find.text('Abbrechen'));
    await settle(tester);

    expect(await answer, isFalse);
  });
}
