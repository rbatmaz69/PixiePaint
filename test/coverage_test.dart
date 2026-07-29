import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/coverage.dart';
import 'package:pixiepaint/canvas/magic_wand.dart' show kWandMinAlpha;
import 'package:pixiepaint/canvas/region_label.dart';

/// Alpha map helper: 255 where [wall] returns true. Same shape as the one in
/// region_label_test.dart, because the input here is that test's output.
Uint8List _walls(int w, int h, bool Function(int x, int y) wall) {
  final alpha = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (wall(x, y)) alpha[y * w + x] = 255;
    }
  }
  return alpha;
}

/// A rectangle of one square box in the middle, the way a coloring page is
/// built: one enclosed area plus the paper around it.
Uint16List _boxPage(int size, {int margin = 8}) {
  final alpha = _walls(
    size,
    size,
    (x, y) =>
        x >= margin &&
        x <= size - 1 - margin &&
        y >= margin &&
        y <= size - 1 - margin &&
        (x == margin ||
            x == size - 1 - margin ||
            y == margin ||
            y == size - 1 - margin),
  );
  return labelRegions(alpha, size, size);
}

/// Empty paint layer.
Uint8List _blank(int w, int h) => Uint8List(w * h * 4);

/// Paints [where] opaque on a copy of [rgba].
Uint8List _paint(
  Uint8List rgba,
  int w,
  int h,
  bool Function(int x, int y) where,
) {
  final out = Uint8List.fromList(rgba);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!where(x, y)) continue;
      final i = (y * w + x) * 4;
      out[i] = 200;
      out[i + 1] = 60;
      out[i + 2] = 120;
      out[i + 3] = 255;
    }
  }
  return out;
}

void main() {
  const s = 32;

  test('a page with nothing painted: one empty region, fraction 0', () {
    final report = regionCoverage(
      regionOf: _boxPage(s),
      rgba: _blank(s, s),
      width: s,
      height: s,
    );
    expect(report.regions, 1, reason: 'the box inside; the paper is border');
    expect(report.fraction, 0);
    expect(report.empty, hasLength(1));
    expect(report.allPainted, isFalse);
  });

  test('the paper around the motif is never counted or pointed at', () {
    // Everything except the box interior is one region touching the border.
    // If it counted, an untouched background would keep every picture at
    // "not finished" and sparkle over the whole sheet.
    final report = regionCoverage(
      regionOf: _boxPage(s),
      rgba: _blank(s, s),
      width: s,
      height: s,
    );
    expect(report.regions, 1);
    expect(report.empty.single.pixels, lessThan(s * s ~/ 2));
  });

  test('a filled box counts as painted and reports no empty area', () {
    final regionOf = _boxPage(s);
    final rgba = _paint(_blank(s, s), s, s,
        (x, y) => x > 8 && x < s - 9 && y > 8 && y < s - 9);
    final report = regionCoverage(
      regionOf: regionOf,
      rgba: rgba,
      width: s,
      height: s,
    );
    expect(report.fraction, 1);
    expect(report.empty, isEmpty);
    expect(report.allPainted, isTrue);
  });

  test('scribbling roughly inside the lines is enough', () {
    // Two thirds covered — a real child's colouring, not a bucket fill.
    final regionOf = _boxPage(s);
    final rgba = _paint(_blank(s, s),
        s, s, (x, y) => x > 8 && x < s - 9 && y > 8 && y < s - 14);
    final report = regionCoverage(
      regionOf: regionOf,
      rgba: rgba,
      width: s,
      height: s,
    );
    expect(report.fraction, greaterThan(kRegionPainted));
    expect(report.empty, isEmpty, reason: 'over the per-region threshold');
  });

  test('a barely touched region is still empty', () {
    final regionOf = _boxPage(s);
    final rgba = _paint(_blank(s, s), s, s, (x, y) => x == 12 && y == 12);
    final report = regionCoverage(
      regionOf: regionOf,
      rgba: rgba,
      width: s,
      height: s,
    );
    expect(report.empty, hasLength(1));
    expect(report.fraction, lessThan(0.1));
  });

  test('paint is the same threshold the magic wand uses', () {
    final regionOf = _boxPage(s);
    final rgba = _blank(s, s);
    // Fill the box interior with exactly one step below the threshold.
    for (var y = 9; y < s - 9; y++) {
      for (var x = 9; x < s - 9; x++) {
        rgba[(y * s + x) * 4 + 3] = kWandMinAlpha - 1;
      }
    }
    expect(
      regionCoverage(regionOf: regionOf, rgba: rgba, width: s, height: s)
          .fraction,
      0,
    );
    for (var y = 9; y < s - 9; y++) {
      for (var x = 9; x < s - 9; x++) {
        rgba[(y * s + x) * 4 + 3] = kWandMinAlpha;
      }
    }
    expect(
      regionCoverage(regionOf: regionOf, rgba: rgba, width: s, height: s)
          .fraction,
      1,
    );
  });

  test('slivers below the minimum size are ignored', () {
    // Two boxes: a big one and one of 3×3 pixels, the kind antialiasing
    // leaves between close lines. Only the big one is worth pointing at.
    final alpha = _walls(s, s, (x, y) {
      final big = x >= 4 && x <= 20 && y >= 4 && y <= 20 &&
          (x == 4 || x == 20 || y == 4 || y == 20);
      final tiny = x >= 24 && x <= 28 && y >= 24 && y <= 28 &&
          (x == 24 || x == 28 || y == 24 || y == 28);
      return big || tiny;
    });
    final regionOf = labelRegions(alpha, s, s);
    final report = regionCoverage(
      regionOf: regionOf,
      rgba: _blank(s, s),
      width: s,
      height: s,
    );
    expect(report.regions, 1, reason: '3×3 interior is under kMinRegionPixels');
    expect(report.empty.single.pixels, greaterThan(kMinRegionPixels));
  });

  test('no line art at all: nothing to measure, and it says so', () {
    // Free drawing — labelRegions returns a single region covering the sheet,
    // which touches the border and therefore drops out. hasRegions is the
    // flag callers must check before reading fraction.
    final regionOf = labelRegions(Uint8List(s * s), s, s);
    final report = regionCoverage(
      regionOf: regionOf,
      rgba: _blank(s, s),
      width: s,
      height: s,
    );
    expect(report.hasRegions, isFalse);
    expect(report.allPainted, isFalse);
    expect(report.fraction, 0);
  });

  test('the hint lands inside its own region, not beside it', () {
    // A thin L: its centre of mass falls in the missing quadrant, which is
    // wall here. Unsnapped, the sparkle would sit on the outline pointing at
    // nothing. (Checked: the raw centroid really does land outside — without
    // the snap this test fails.)
    final alpha = _walls(s, s, (x, y) {
      const l = 6, r = 26, t = 6, b = 26;
      final onFrame = (x == l || x == r || y == t || y == b) &&
          x >= l && x <= r && y >= t && y <= b;
      final block = x >= 12 && x <= r && y >= t && y <= 20;
      return onFrame || block;
    });
    final regionOf = labelRegions(alpha, s, s);
    final report = regionCoverage(
      regionOf: regionOf,
      rgba: _blank(s, s),
      width: s,
      height: s,
    );
    expect(report.empty, isNotEmpty);
    for (final e in report.empty) {
      final px = e.x.round(), py = e.y.round();
      expect(regionOf[py * s + px], e.id,
          reason: 'hint at ($px,$py) must sit in region ${e.id}');
    }
  });

  test('biggest gap first', () {
    final alpha = _walls(64, 64, (x, y) {
      final small = x >= 2 && x <= 12 && y >= 2 && y <= 12 &&
          (x == 2 || x == 12 || y == 2 || y == 12);
      final big = x >= 20 && x <= 60 && y >= 20 && y <= 60 &&
          (x == 20 || x == 60 || y == 20 || y == 60);
      return small || big;
    });
    final report = regionCoverage(
      regionOf: labelRegions(alpha, 64, 64),
      rgba: _blank(64, 64),
      width: 64,
      height: 64,
    );
    expect(report.empty, hasLength(2));
    expect(report.empty.first.pixels,
        greaterThan(report.empty.last.pixels));
  });

  test('a mismatched buffer is answered, not thrown at', () {
    final report = regionCoverage(
      regionOf: _boxPage(s),
      rgba: Uint8List(4),
      width: s,
      height: s,
    );
    expect(report.hasRegions, isFalse);
  });
}
