import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/ui/oops_card.dart';
import 'package:pixiepaint/util/error_log.dart';

import 'harness.dart';

/// A widget that really throws in `build` — the only honest way to test what
/// a child meets when something breaks.
class _Exploding extends StatelessWidget {
  const _Exploding();

  @override
  Widget build(BuildContext context) => throw StateError('absichtlich kaputt');
}

/// What happens on the other side of a failed build.
///
/// `main()` installs exactly this pair in release builds: the friendly card as
/// `ErrorWidget.builder`, and `FlutterError.onError` writing the failure down.
/// Both are set up by hand here, because `kReleaseMode` is false under
/// `flutter test` — the wiring is one line in main.dart, the behaviour worth
/// testing is this.
void main() {
  testWidgets('a broken subtree shows the card, not a grey box',
      (tester) async {
    // Restored inside the body, not in a tearDown: the test framework asserts
    // that `ErrorWidget.builder` is back to normal by the time the body ends.
    final previous = ErrorWidget.builder;
    ErrorWidget.builder = (details) => const OopsCard();
    await pumpPixie(tester, const _Exploding());
    await tester.pump();
    ErrorWidget.builder = previous;

    // The framework hands the exception to the test as a failure unless it is
    // taken; taking it here is the test saying "yes, that one was on purpose".
    expect(tester.takeException(), isA<StateError>());
    expect(find.byType(OopsCard), findsOneWidget);
    expect(find.textContaining('Ups'), findsOneWidget);
    // Whatever else it does, it must not offer a button that cannot know
    // where to go back to.
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('the failure is recorded once, not once per frame',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('pp_oops');
    final log = ErrorLog.instance;
    await tester.runAsync(() async {
      log.resetForTest();
      await log.initIn(dir);
    });

    addTearDown(() {
      log.resetForTest();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final previousBuilder = ErrorWidget.builder;
    final previousOnError = FlutterError.onError;
    ErrorWidget.builder = (details) => const OopsCard();
    FlutterError.onError = (details) => log
        .record(details.exception, details.stack, origin: ErrorOrigin.flutter);

    await pumpPixie(tester, const _Exploding());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    ErrorWidget.builder = previousBuilder;
    FlutterError.onError = previousOnError;

    expect(log.count, 1, reason: 'one failure, one entry');
    expect(log.entries.single.message, contains('absichtlich kaputt'));
  });
}
