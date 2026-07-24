import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_screen.dart';
import 'package:pixiepaint/util/settings.dart';

import 'harness.dart';

/// Can a child actually *reach* the controls?
///
/// Until v8.0 undo sat at the end of the toolbar's scrolling strip — the
/// nineteenth button of a row about a thousand pixels wide, on a phone that
/// shows three hundred and sixty. It was reachable in the sense that a
/// gesture nothing announced would eventually get you there. These tests
/// hold the fix: the two buttons that undo a mistake are on screen when the
/// picture opens, whichever hand the child draws with.
///
/// The size below is a small phone in portrait (360 × 640 dp), which is the
/// worst case the app ships to.
const Size _phonePortrait = Size(360, 640);

void main() {
  late Directory root;
  var opened = 0;

  setUp(() => opened = 0);

  /// Opens a *fresh* canvas. The key matters: two `const CanvasScreen()`
  /// widgets in a row would update the same element, keep the same State and
  /// never run `initState` again — which is exactly what "open the next
  /// picture" has to do.
  Future<void> openCanvas(WidgetTester tester,
      {Size size = _phonePortrait}) async {
    // Free drawing: nothing to rasterize, so the canvas is up after a frame.
    await pumpPixie(tester, CanvasScreen(key: ValueKey(opened++)), size: size);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('undo is on screen without scrolling, on a small phone',
      (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    final handle = tester.ensureSemantics();

    await openCanvas(tester);

    final undo = tester.getRect(find.bySemanticsLabel('Rückgängig'));
    expect(undo.left, greaterThanOrEqualTo(0));
    expect(undo.right, lessThanOrEqualTo(_phonePortrait.width),
        reason: 'undo must not need a scroll gesture to reach');

    // The counter-proof: the strip really does overflow. Without this the
    // test above would still pass on a toolbar that simply got shorter, and
    // would stop describing the bug it was written for.
    final eraser = tester.getRect(find.bySemanticsLabel('Radierer'));
    expect(eraser.right, greaterThan(_phonePortrait.width),
        reason: 'the tool strip is expected to scroll — that is the point');

    handle.dispose();
  });

  testWidgets('the action cluster changes sides for a left-handed child',
      (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    final handle = tester.ensureSemantics();

    await openCanvas(tester);
    final rightHanded = tester.getRect(find.bySemanticsLabel('Rückgängig'));
    expect(rightHanded.center.dx,
        greaterThan(tester.getRect(find.bySemanticsLabel('Pinsel')).center.dx));

    // Fire-and-forget on purpose. The field is set before the first await,
    // which is all this test needs — awaiting it would hang, because the
    // canvas above already queued a settings write inside the fake-async
    // zone, where real file I/O never completes.
    unawaited(Settings.instance.update(leftHanded: true));
    await openCanvas(tester);

    final leftHanded = tester.getRect(find.bySemanticsLabel('Rückgängig'));
    expect(leftHanded.center.dx,
        lessThan(tester.getRect(find.bySemanticsLabel('Pinsel')).center.dx),
        reason: 'the cluster belongs on the side the drawing arm is not');
    expect(leftHanded.left, greaterThanOrEqualTo(0));

    handle.dispose();
  });

  group('the rotate nudge', () {
    testWidgets('appears once on a phone and marks itself seen',
        (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(root));

      await openCanvas(tester);
      expect(find.text('Quer hast du mehr Platz zum Malen'), findsOneWidget);
      expect(Settings.instance.rotateHintSeen, isTrue);

      // Second picture, same day: the child has been told.
      await openCanvas(tester);
      expect(find.text('Quer hast du mehr Platz zum Malen'), findsNothing);
    });

    testWidgets('stays away on a tablet, where upright is fine', (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(root));

      await openCanvas(tester, size: const Size(800, 1200));

      expect(find.text('Quer hast du mehr Platz zum Malen'), findsNothing);
      expect(Settings.instance.rotateHintSeen, isFalse);
    });

    testWidgets('goes away by itself', (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(root));

      await openCanvas(tester);
      expect(find.text('Quer hast du mehr Platz zum Malen'), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Quer hast du mehr Platz zum Malen'), findsNothing);
    });
  });
}
