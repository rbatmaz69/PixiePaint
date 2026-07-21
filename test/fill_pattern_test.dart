import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/fill_pattern.dart';
import 'package:pixiepaint/canvas/flood_fill.dart';

void main() {
  test('solid returns the base color', () {
    expect(patternColorAt(FillPattern.solid, 17, 93, 0x12, 0x34, 0x56),
        0x123456);
  });

  test('patterns are deterministic', () {
    for (final p in FillPattern.values) {
      expect(patternColorAt(p, 41, 87, 200, 30, 60),
          patternColorAt(p, 41, 87, 200, 30, 60));
    }
  });

  test('dots: white dot at cell center, base color at cell corner', () {
    expect(patternColorAt(FillPattern.dots, 36, 36, 200, 30, 60), 0xFFFFFF);
    expect(patternColorAt(FillPattern.dots, 0, 0, 200, 30, 60), 0xC81E3C);
  });

  test('stripes alternate between base and a lighter tone', () {
    final a = patternColorAt(FillPattern.stripes, 0, 0, 200, 30, 60);
    final c = patternColorAt(FillPattern.stripes, 56, 0, 200, 30, 60);
    expect(a, 0xC81E3C);
    expect(c, isNot(a));
    // Lighter: every channel >= base channel.
    expect((c >> 16) & 0xFF, greaterThanOrEqualTo(200));
    expect((c >> 8) & 0xFF, greaterThanOrEqualTo(30));
    expect(c & 0xFF, greaterThanOrEqualTo(60));
  });

  test('stripes and dots repeat with their period', () {
    for (var i = 0; i < 200; i += 7) {
      expect(patternColorAt(FillPattern.stripes, i, i, 10, 20, 30),
          patternColorAt(FillPattern.stripes, i + 112, i, 10, 20, 30));
      expect(patternColorAt(FillPattern.dots, i, i, 10, 20, 30),
          patternColorAt(FillPattern.dots, i + 72, i + 72, 10, 20, 30));
    }
  });

  test('rainbow cycles hue over 600 canvas px and ignores nothing but base',
      () {
    final a = patternColorAt(FillPattern.rainbow, 0, 0, 1, 2, 3);
    final b = patternColorAt(FillPattern.rainbow, 200, 0, 1, 2, 3);
    final c = patternColorAt(FillPattern.rainbow, 600, 0, 1, 2, 3);
    expect(a, isNot(b));
    expect(a, c);
  });

  test('hearts: white heart at cell center, base color at cell corner', () {
    // Cell 84, even row: heart center sits at (42, ~38).
    expect(patternColorAt(FillPattern.hearts, 42, 38, 200, 30, 60), 0xFFFFFF);
    expect(patternColorAt(FillPattern.hearts, 2, 2, 200, 30, 60), 0xC81E3C);
  });

  test('stars: white sparkle at cell center, base color at cell corner', () {
    // Cell 88, even row: star center sits at (44, 44).
    expect(patternColorAt(FillPattern.stars, 44, 44, 200, 30, 60), 0xFFFFFF);
    expect(patternColorAt(FillPattern.stars, 2, 2, 200, 30, 60), 0xC81E3C);
  });

  test('checker alternates base and a lighter tone with period 128', () {
    final a = patternColorAt(FillPattern.checker, 0, 0, 200, 30, 60);
    final c = patternColorAt(FillPattern.checker, 64, 0, 200, 30, 60);
    expect(a, 0xC81E3C);
    expect(c, isNot(a));
    expect((c >> 16) & 0xFF, greaterThanOrEqualTo(200));
    for (var i = 0; i < 200; i += 7) {
      expect(patternColorAt(FillPattern.checker, i, i, 10, 20, 30),
          patternColorAt(FillPattern.checker, i + 128, i, 10, 20, 30));
    }
  });

  test('bubbles: white ring at radius 26, base inside and outside', () {
    // Cell 96: bubble center at (48, 48), ring spans radius 23..29.
    expect(patternColorAt(FillPattern.bubbles, 48 + 26, 48, 200, 30, 60),
        0xFFFFFF);
    expect(patternColorAt(FillPattern.bubbles, 48, 48, 200, 30, 60),
        0xC81E3C);
    expect(patternColorAt(FillPattern.bubbles, 0, 0, 200, 30, 60), 0xC81E3C);
  });

  test('new patterns repeat with their cell period', () {
    for (var i = 0; i < 200; i += 7) {
      // Rows stagger, so compare two full row heights apart.
      expect(patternColorAt(FillPattern.hearts, i, i, 10, 20, 30),
          patternColorAt(FillPattern.hearts, i + 84, i + 168, 10, 20, 30));
      expect(patternColorAt(FillPattern.stars, i, i, 10, 20, 30),
          patternColorAt(FillPattern.stars, i + 88, i + 176, 10, 20, 30));
      expect(patternColorAt(FillPattern.bubbles, i, i, 10, 20, 30),
          patternColorAt(FillPattern.bubbles, i + 96, i + 96, 10, 20, 30));
    }
  });

  test('hsvToRgb hits the primary corners', () {
    expect(hsvToRgb(0, 1, 1), 0xFF0000);
    expect(hsvToRgb(120, 1, 1), 0x00FF00);
    expect(hsvToRgb(240, 1, 1), 0x0000FF);
    expect(hsvToRgb(0, 0, 1), 0xFFFFFF);
  });

  test('patterned flood fill covers the same region as solid', () {
    const w = 32, h = 32;
    final solid = floodFill(
      rgba: Uint8List(w * h * 4),
      barrierAlpha: null,
      width: w,
      height: h,
      seedX: 5,
      seedY: 5,
      fillR: 200,
      fillG: 30,
      fillB: 60,
      dilationPasses: 0,
    )!;
    final dotted = floodFill(
      rgba: Uint8List(w * h * 4),
      barrierAlpha: null,
      width: w,
      height: h,
      seedX: 5,
      seedY: 5,
      fillR: 200,
      fillG: 30,
      fillB: 60,
      dilationPasses: 0,
      pattern: FillPattern.dots,
    )!;
    for (var i = 0; i < w * h; i++) {
      expect(dotted[i * 4 + 3], solid[i * 4 + 3],
          reason: 'coverage differs at pixel $i');
      final expected =
          patternColorAt(FillPattern.dots, i % w, i ~/ w, 200, 30, 60);
      expect(dotted[i * 4], (expected >> 16) & 0xFF);
      expect(dotted[i * 4 + 1], (expected >> 8) & 0xFF);
      expect(dotted[i * 4 + 2], expected & 0xFF);
    }
  });

  test('patterned fill over an already-filled flat region is not a no-op',
      () {
    const w = 16, h = 16;
    final rgba = Uint8List(w * h * 4);
    for (var i = 0; i < w * h; i++) {
      rgba[i * 4] = 200;
      rgba[i * 4 + 1] = 30;
      rgba[i * 4 + 2] = 60;
      rgba[i * 4 + 3] = 255;
    }
    final result = floodFill(
      rgba: rgba,
      barrierAlpha: null,
      width: w,
      height: h,
      seedX: 8,
      seedY: 8,
      fillR: 200,
      fillG: 30,
      fillB: 60,
      dilationPasses: 0,
      pattern: FillPattern.stripes,
    );
    expect(result, isNotNull);
  });
}
