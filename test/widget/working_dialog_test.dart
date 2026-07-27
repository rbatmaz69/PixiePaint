import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/ui/working_dialog.dart';

import 'harness.dart';

/// The parents' exports used to run in silence, and two of them swallowed
/// their exception whole — a printer that refused the job looked exactly
/// like a button that had not registered the tap.
void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  /// Puts a button on screen that runs [work] behind the dialog. The result
  /// is left in [done] to be awaited *after* the tester is finished driving,
  /// the same trick parental_gate_test uses.
  late Future<String?> done;

  Future<void> run(WidgetTester tester, Future<String> Function() work) async {
    final root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));
    await pumpPixie(
      tester,
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => done = runWithWorkingDialog<String>(
              context: context,
              emoji: '🖨️',
              title: 'Einen Moment …',
              failedTitle: 'Das Drucken hat nicht geklappt',
              work: work,
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await settle(tester);
  }

  testWidgets('it says it is working, then gets out of the way',
      (tester) async {
    final gate = Completer<String>();
    await run(tester, () => gate.future);

    expect(find.text('Einen Moment …'), findsOneWidget);

    gate.complete('ok');
    await settle(tester);

    expect(find.text('Einen Moment …'), findsNothing);
    expect(await done, 'ok');
  });

  testWidgets('a failure is said out loud, not swallowed', (tester) async {
    await run(tester, () => Future<String>.error(StateError('no printer')));

    // The card that used to be a `catch (_) {}`.
    expect(find.text('Das Drucken hat nicht geklappt'), findsOneWidget);
    expect(find.text('Einen Moment …'), findsNothing,
        reason: 'the working card gives way to the failure card');

    await tester.tap(find.text('Okay!'));
    await settle(tester);

    expect(await done, isNull, reason: 'null is how the caller learns it failed');
  });
}
