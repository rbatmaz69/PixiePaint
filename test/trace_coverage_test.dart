import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/trace/trace_coverage.dart';

/// Builds an alpha map with a horizontal guide bar from (x0..x1) at [y]
/// with the given thickness.
Uint8List _barAlpha(int w, int h, int x0, int x1, int y, int thickness) {
  final alpha = Uint8List(w * h);
  for (var yy = y; yy < y + thickness && yy < h; yy++) {
    for (var xx = x0; xx < x1 && xx < w; xx++) {
      alpha[yy * w + xx] = 255;
    }
  }
  return alpha;
}

void main() {
  test('empty alpha yields zero fraction and never divides by zero', () {
    final c = TraceCoverage.fromAlpha(Uint8List(64 * 64), 64, 64, cell: 16);
    c.addPoint(32, 32, 20);
    expect(c.fraction, 0);
  });

  test('points far from the guide do not count', () {
    final alpha = _barAlpha(256, 256, 0, 256, 16, 8);
    final c = TraceCoverage.fromAlpha(alpha, 256, 256, cell: 32);
    c.addPoint(128, 220, 10);
    expect(c.fraction, 0);
  });

  test('tracing along the guide reaches full coverage', () {
    final alpha = _barAlpha(256, 256, 0, 256, 60, 8);
    final c = TraceCoverage.fromAlpha(alpha, 256, 256, cell: 32);
    for (var x = 0; x <= 256; x += 8) {
      c.addPoint(x.toDouble(), 64, 24);
    }
    expect(c.fraction, 1.0);
  });

  test('half a trace is roughly half the fraction', () {
    final alpha = _barAlpha(256, 256, 0, 256, 60, 8);
    final c = TraceCoverage.fromAlpha(alpha, 256, 256, cell: 32);
    for (var x = 0; x <= 128; x += 8) {
      c.addPoint(x.toDouble(), 64, 20);
    }
    expect(c.fraction, greaterThan(0.35));
    expect(c.fraction, lessThan(0.75));
  });

  test('re-visiting the same cells never overcounts', () {
    final alpha = _barAlpha(256, 256, 0, 256, 60, 8);
    final c = TraceCoverage.fromAlpha(alpha, 256, 256, cell: 32);
    for (var pass = 0; pass < 3; pass++) {
      c.addPoints(
          [for (var x = 0; x <= 256; x += 8) Offset(x.toDouble(), 64)], 24);
    }
    expect(c.fraction, 1.0);
  });

  test('out-of-bounds points are clamped, not crashing', () {
    final alpha = _barAlpha(256, 256, 0, 256, 4, 8);
    final c = TraceCoverage.fromAlpha(alpha, 256, 256, cell: 32);
    c.addPoint(-50, -50, 40);
    c.addPoint(500, 500, 40);
    expect(c.fraction, greaterThanOrEqualTo(0));
  });
}
