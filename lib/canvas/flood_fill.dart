import 'dart:typed_data';

import 'fill_pattern.dart';

/// Scanline flood fill over an RGBA byte buffer. Pure Dart, no dart:ui —
/// safe to run via `Isolate.run`.
///
/// [rgba] is the paint layer (straight RGBA, w*h*4 bytes) and is modified
/// in place. [barrierAlpha] is the alpha channel of the rasterized line
/// art (w*h bytes) or null in free-draw mode; pixels with alpha > 128 are
/// walls. [pattern] paints the region with a pattern derived from the fill
/// color instead of the flat color. Returns the modified buffer, or null if
/// the fill was a no-op (seed on a wall, or region already has the fill
/// color).
Uint8List? floodFill({
  required Uint8List rgba,
  required Uint8List? barrierAlpha,
  required int width,
  required int height,
  required int seedX,
  required int seedY,
  required int fillR,
  required int fillG,
  required int fillB,
  int tolerance = 32,
  int dilationPasses = 3,
  FillPattern pattern = FillPattern.solid,
}) {
  if (seedX < 0 || seedY < 0 || seedX >= width || seedY >= height) return null;
  final seedIdx = seedY * width + seedX;
  if (barrierAlpha != null && barrierAlpha[seedIdx] > 128) return null;

  final tr = rgba[seedIdx * 4];
  final tg = rgba[seedIdx * 4 + 1];
  final tb = rgba[seedIdx * 4 + 2];
  final ta = rgba[seedIdx * 4 + 3];

  // Already this color? No-op so we don't push junk undo states. (Patterned
  // fills always repaint — adding dots to a flat region is meaningful.)
  if (pattern == FillPattern.solid &&
      ta == 255 &&
      (tr - fillR).abs() <= 8 &&
      (tg - fillG).abs() <= 8 &&
      (tb - fillB).abs() <= 8) {
    return null;
  }

  final filled = Uint8List(width * height);

  bool matches(int i) {
    if (filled[i] != 0) return false;
    if (barrierAlpha != null && barrierAlpha[i] > 128) return false;
    final o = i * 4;
    return (rgba[o] - tr).abs() <= tolerance &&
        (rgba[o + 1] - tg).abs() <= tolerance &&
        (rgba[o + 2] - tb).abs() <= tolerance &&
        (rgba[o + 3] - ta).abs() <= tolerance;
  }

  // Span-based scanline fill.
  final stack = <int>[seedIdx];
  while (stack.isNotEmpty) {
    final idx = stack.removeLast();
    if (!matches(idx)) continue;
    final y = idx ~/ width;
    var x0 = idx % width;
    var x1 = x0;
    // walk left
    while (x0 > 0 && matches(y * width + x0 - 1)) {
      x0--;
    }
    // walk right
    while (x1 < width - 1 && matches(y * width + x1 + 1)) {
      x1++;
    }
    for (var x = x0; x <= x1; x++) {
      filled[y * width + x] = 1;
    }
    // seed spans above and below
    for (final ny in [y - 1, y + 1]) {
      if (ny < 0 || ny >= height) continue;
      var inSpan = false;
      for (var x = x0; x <= x1; x++) {
        final ni = ny * width + x;
        if (matches(ni)) {
          if (!inSpan) {
            stack.add(ni);
            inSpan = true;
          }
        } else {
          inSpan = false;
        }
      }
    }
  }

  // Dilate the filled region under the anti-aliased line edges so no white
  // halo remains along outlines. Only pixels that belong to the line art
  // (alpha > 0) are overpainted; the line art is drawn on top, so this is
  // invisible except for removing the fringe.
  if (barrierAlpha != null) {
    var frontier = <int>[];
    for (var i = 0; i < filled.length; i++) {
      if (filled[i] != 0) frontier.add(i);
    }
    for (var pass = 0; pass < dilationPasses; pass++) {
      final next = <int>[];
      for (final i in frontier) {
        final x = i % width;
        final y = i ~/ width;
        for (final n in [
          if (x > 0) i - 1,
          if (x < width - 1) i + 1,
          if (y > 0) i - width,
          if (y < height - 1) i + width,
        ]) {
          if (filled[n] == 0 && barrierAlpha[n] > 0) {
            filled[n] = 1;
            next.add(n);
          }
        }
      }
      frontier = next;
      if (frontier.isEmpty) break;
    }
  }

  for (var i = 0; i < filled.length; i++) {
    if (filled[i] != 0) {
      final o = i * 4;
      var r = fillR, g = fillG, b = fillB;
      if (pattern != FillPattern.solid) {
        final c = patternColorAt(pattern, i % width, i ~/ width, r, g, b);
        r = (c >> 16) & 0xFF;
        g = (c >> 8) & 0xFF;
        b = c & 0xFF;
      }
      rgba[o] = r;
      rgba[o + 1] = g;
      rgba[o + 2] = b;
      rgba[o + 3] = 255;
    }
  }
  return rgba;
}
