import 'dart:typed_data';
import 'dart:ui' show Offset;

import '../models/cbn_spec.dart';

/// The rules of a color-by-number page, free of any widget or dart:ui
/// rendering — which is what makes them testable.
///
/// The session owns which regions are already solved, which number is
/// selected and how a wrong tap is answered. Deliberately forgiving:
/// unlabeled areas (the background around the motif) may always be filled,
/// and a wrong number is never punished — after the second miss the correct
/// swatch is pointed out instead.
class CbnSession {
  CbnSession({
    required this.spec,
    required this.regionOf,
    required this.width,
    required this.height,
    required Map<int, int> regionNumber,
    Iterable<int> alreadyFilled = const [],
  }) : _regionNumber = Map.of(regionNumber) {
    filledRegions.addAll(alreadyFilled);
    selected = firstOpenNumber ?? spec.numbers.first;
  }

  /// Builds a session from a page's sidecar plus its labeled region map,
  /// resolving every label position to the region it sits in. Labels that
  /// land on an outline (region 0) are an authoring slip and are skipped.
  factory CbnSession.fromLabels({
    required CbnSpec spec,
    required Uint16List regionOf,
    required int width,
    required int height,
    Iterable<int> alreadyFilled = const [],
  }) {
    final regionNumber = <int, int>{};
    for (final label in spec.labels) {
      final id = _regionAt(regionOf, width, height, label.pos);
      if (id != 0) regionNumber[id] = label.number;
    }
    return CbnSession(
      spec: spec,
      regionOf: regionOf,
      width: width,
      height: height,
      regionNumber: regionNumber,
      alreadyFilled: alreadyFilled,
    );
  }

  final CbnSpec spec;
  final Uint16List regionOf;
  final int width;
  final int height;
  final Map<int, int> _regionNumber;

  final Set<int> filledRegions = {};
  late int selected;

  /// Consecutive taps with the wrong number; drives the hint.
  int wrongTries = 0;

  static int _regionAt(
      Uint16List regionOf, int width, int height, Offset pos) {
    final x = pos.dx.floor().clamp(0, width - 1);
    final y = pos.dy.floor().clamp(0, height - 1);
    return regionOf[y * width + x];
  }

  int regionAt(Offset pos) => _regionAt(regionOf, width, height, pos);

  bool get isComplete =>
      _regionNumber.isNotEmpty &&
      _regionNumber.keys.every(filledRegions.contains);

  /// Numbers whose regions are all filled — they get a check badge.
  Set<int> get doneNumbers {
    final done = <int>{};
    for (final n in spec.numbers) {
      var any = false;
      var all = true;
      for (final entry in _regionNumber.entries) {
        if (entry.value != n) continue;
        any = true;
        if (!filledRegions.contains(entry.key)) all = false;
      }
      if (any && all) done.add(n);
    }
    return done;
  }

  int? get firstOpenNumber {
    final done = doneNumbers;
    for (final n in spec.numbers) {
      if (!done.contains(n)) return n;
    }
    return null;
  }

  void select(int number) {
    if (spec.colorOf[number] == null) return;
    selected = number;
  }

  /// Label chips for the painter; solved ones are hidden.
  List<({Offset pos, int number, bool filled})> labels() => [
        for (final label in spec.labels)
          (
            pos: label.pos,
            number: label.number,
            filled: filledRegions.contains(regionAt(label.pos)),
          ),
      ];

  /// Decides what a fill tap at [pos] should do.
  CbnTap tapAt(Offset pos) {
    final number = _regionNumber[regionAt(pos)];
    // Unlabeled area (background) — let the kid paint it in any color.
    if (number == null || number == selected) {
      return const CbnTap.allowed();
    }
    wrongTries++;
    // First miss passes silently; from the second on, point at the right
    // swatch.
    return CbnTap.wrong(number, showHint: wrongTries >= 2);
  }

  /// Records a completed fill. Returns what changed so the screen knows
  /// whether to celebrate or move the selection on.
  CbnFillResult registerFill(Offset pos) {
    final id = regionAt(pos);
    if (_regionNumber[id] == null || !filledRegions.add(id)) {
      return const CbnFillResult(counted: false);
    }
    wrongTries = 0;
    // Hop to the next open number so the kid always knows what comes next.
    int? nextSelection;
    if (doneNumbers.contains(selected)) {
      final next = firstOpenNumber;
      if (next != null) {
        selected = next;
        nextSelection = next;
      }
    }
    return CbnFillResult(
      counted: true,
      nextSelection: nextSelection,
      completed: isComplete,
    );
  }
}

/// Verdict for a fill tap.
class CbnTap {
  const CbnTap.allowed()
      : allowed = true,
        correctNumber = null,
        showHint = false;

  const CbnTap.wrong(this.correctNumber, {required this.showHint})
      : allowed = false;

  final bool allowed;

  /// The number that region actually wants (null when the tap is allowed).
  final int? correctNumber;

  /// Whether the correct swatch should pulse now.
  final bool showHint;
}

class CbnFillResult {
  const CbnFillResult({
    required this.counted,
    this.nextSelection,
    this.completed = false,
  });

  /// False when the tap hit an unlabeled area or an already-solved region.
  final bool counted;

  /// Set when the selection moved on to the next open number.
  final int? nextSelection;

  /// True on the fill that finished the whole picture.
  final bool completed;
}
