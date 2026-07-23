import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/cbn_session.dart';
import 'package:pixiepaint/models/cbn_spec.dart';

/// A 4×1 strip of regions: [1][2][3][background].
const _w = 4, _h = 1;

CbnSession _session({Iterable<int> filled = const []}) {
  final regionOf = Uint16List.fromList([10, 20, 30, 40]);
  const spec = CbnSpec(
    numbers: [1, 2, 3],
    colorOf: {1: Color(0xFFFF0000), 2: Color(0xFF00FF00), 3: Color(0xFF0000FF)},
    labels: [
      CbnLabel(1, Offset(0, 0)),
      CbnLabel(2, Offset(1, 0)),
      CbnLabel(3, Offset(2, 0)),
      // region 40 stays unlabeled → free background
    ],
  );
  return CbnSession.fromLabels(
    spec: spec,
    regionOf: regionOf,
    width: _w,
    height: _h,
    alreadyFilled: filled,
  );
}

void main() {
  test('starts on the first number and nothing is done', () {
    final s = _session();
    expect(s.selected, 1);
    expect(s.doneNumbers, isEmpty);
    expect(s.isComplete, isFalse);
  });

  test('tapping the matching region is allowed', () {
    final s = _session();
    expect(s.tapAt(const Offset(0, 0)).allowed, isTrue);
  });

  test('unlabeled background may always be filled, whatever is selected', () {
    final s = _session();
    expect(s.tapAt(const Offset(3, 0)).allowed, isTrue);
    s.select(3);
    expect(s.tapAt(const Offset(3, 0)).allowed, isTrue);
  });

  test('the first wrong tap is silent, the second one hints', () {
    final s = _session();
    final first = s.tapAt(const Offset(1, 0)); // region wants 2, 1 selected
    expect(first.allowed, isFalse);
    expect(first.correctNumber, 2);
    expect(first.showHint, isFalse, reason: 'never scold on the first try');

    final second = s.tapAt(const Offset(1, 0));
    expect(second.showHint, isTrue);
    expect(second.correctNumber, 2);
  });

  test('a correct fill resets the wrong-try counter', () {
    final s = _session();
    s.tapAt(const Offset(1, 0));
    s.tapAt(const Offset(1, 0));
    expect(s.wrongTries, 2);
    s.registerFill(const Offset(0, 0));
    expect(s.wrongTries, 0);
    // The next miss is quiet again.
    expect(s.tapAt(const Offset(2, 0)).showHint, isFalse);
  });

  test('filling a number advances the selection to the next open one', () {
    final s = _session();
    final result = s.registerFill(const Offset(0, 0));
    expect(result.counted, isTrue);
    expect(result.nextSelection, 2);
    expect(s.selected, 2);
    expect(s.doneNumbers, {1});
  });

  test('filling the background counts for nothing', () {
    final s = _session();
    final result = s.registerFill(const Offset(3, 0));
    expect(result.counted, isFalse);
    expect(result.completed, isFalse);
    expect(s.selected, 1);
  });

  test('refilling a solved region does not count twice', () {
    final s = _session();
    expect(s.registerFill(const Offset(0, 0)).counted, isTrue);
    expect(s.registerFill(const Offset(0, 0)).counted, isFalse);
  });

  test('completion fires exactly once, on the last region', () {
    final s = _session();
    expect(s.registerFill(const Offset(0, 0)).completed, isFalse);
    expect(s.registerFill(const Offset(1, 0)).completed, isFalse);
    final last = s.registerFill(const Offset(2, 0));
    expect(last.completed, isTrue);
    expect(s.isComplete, isTrue);
    expect(s.doneNumbers, {1, 2, 3});
  });

  test('resuming restores progress and selects the first open number', () {
    final s = _session(filled: [10, 20]);
    expect(s.doneNumbers, {1, 2});
    expect(s.selected, 3, reason: 'skip what the kid already solved');
    expect(s.isComplete, isFalse);
  });

  test('resuming a finished picture reports complete', () {
    final s = _session(filled: [10, 20, 30]);
    expect(s.isComplete, isTrue);
  });

  test('labels report which chips are already solved', () {
    final s = _session(filled: [10]);
    final labels = s.labels();
    expect(labels, hasLength(3));
    expect(labels.firstWhere((l) => l.number == 1).filled, isTrue);
    expect(labels.firstWhere((l) => l.number == 2).filled, isFalse);
  });

  test('labels on an outline (region 0) are skipped, not mis-assigned', () {
    final regionOf = Uint16List.fromList([0, 20, 30, 40]);
    const spec = CbnSpec(
      numbers: [1, 2],
      colorOf: {1: Color(0xFFFF0000), 2: Color(0xFF00FF00)},
      labels: [CbnLabel(1, Offset(0, 0)), CbnLabel(2, Offset(1, 0))],
    );
    final s = CbnSession.fromLabels(
        spec: spec, regionOf: regionOf, width: _w, height: _h);
    // Only number 2 has a real region, so solving it completes the page.
    expect(s.registerFill(const Offset(1, 0)).completed, isTrue);
  });

  test('positions outside the canvas are clamped, not crashing', () {
    final s = _session();
    expect(() => s.tapAt(const Offset(-50, -50)), returnsNormally);
    expect(() => s.registerFill(const Offset(999, 999)), returnsNormally);
  });
}
