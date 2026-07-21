// Pure pattern math for flood fills — no dart:ui / Flutter imports so it can
// run inside the flood-fill isolate (same pattern as flood_fill.dart).

import 'dart:math';

/// How a flood fill paints the region: one flat color or a playful pattern
/// derived from the selected color.
enum FillPattern {
  solid,
  dots,
  stripes,
  rainbow,
  hearts,
  stars,
  checker,
  bubbles,
}

const int _dotCell = 72;
const int _dotRadius = 18;
const int _stripeWidth = 56;
const int _rainbowCycle = 600;
const int _heartCell = 84;
const int _starCell = 88;
const int _checkerSize = 64;
const int _bubbleCell = 96;

/// Base color lightened towards white by [pct] percent, packed 0xRRGGBB.
int _lighten(int r, int g, int b, int pct) {
  final lr = r + ((255 - r) * pct) ~/ 100;
  final lg = g + ((255 - g) * pct) ~/ 100;
  final lb = b + ((255 - b) * pct) ~/ 100;
  return (lr << 16) | (lg << 8) | lb;
}

/// Color of pattern [p] at canvas pixel (x, y) for base color (r, g, b),
/// packed as 0xRRGGBB. Pure and deterministic.
int patternColorAt(FillPattern p, int x, int y, int r, int g, int b) {
  switch (p) {
    case FillPattern.solid:
      return (r << 16) | (g << 8) | b;
    case FillPattern.dots:
      final cx = x % _dotCell - _dotCell ~/ 2;
      final cy = y % _dotCell - _dotCell ~/ 2;
      if (cx * cx + cy * cy <= _dotRadius * _dotRadius) return 0xFFFFFF;
      return (r << 16) | (g << 8) | b;
    case FillPattern.stripes:
      if (((x + y) ~/ _stripeWidth).isEven) return (r << 16) | (g << 8) | b;
      return _lighten(r, g, b, 45);
    case FillPattern.rainbow:
      final hue = ((x + y) % _rainbowCycle) * 360 / _rainbowCycle;
      return hsvToRgb(hue, 0.7, 1.0);
    case FillPattern.hearts:
      // Staggered rows of white hearts via the classic implicit heart
      // curve (u² + v² − 1)³ − u²·v³ ≤ 0.
      final row = y ~/ _heartCell;
      final xs = x + (row.isOdd ? _heartCell ~/ 2 : 0);
      final u = (xs % _heartCell - _heartCell / 2) / (_heartCell * 0.30);
      final v = -(y % _heartCell - _heartCell / 2) / (_heartCell * 0.30) + 0.1;
      final q = u * u + v * v - 1;
      if (q * q * q - u * u * v * v * v <= 0) return 0xFFFFFF;
      return (r << 16) | (g << 8) | b;
    case FillPattern.stars:
      // Four-point sparkle: the astroid |u|^⅔ + |v|^⅔ ≤ 1.
      final row = y ~/ _starCell;
      final xs = x + (row.isOdd ? _starCell ~/ 2 : 0);
      final u = (xs % _starCell - _starCell / 2).abs() / (_starCell * 0.34);
      final v = (y % _starCell - _starCell / 2).abs() / (_starCell * 0.34);
      if (pow(u, 2 / 3) + pow(v, 2 / 3) <= 1) return 0xFFFFFF;
      return (r << 16) | (g << 8) | b;
    case FillPattern.checker:
      if (((x ~/ _checkerSize) + (y ~/ _checkerSize)).isEven) {
        return (r << 16) | (g << 8) | b;
      }
      return _lighten(r, g, b, 45);
    case FillPattern.bubbles:
      // A big and a small soap-bubble ring per cell.
      final cx = x % _bubbleCell - _bubbleCell ~/ 2;
      final cy = y % _bubbleCell - _bubbleCell ~/ 2;
      final d2 = cx * cx + cy * cy;
      if (d2 >= 23 * 23 && d2 <= 29 * 29) return 0xFFFFFF;
      final sx = cx - 34, sy = cy + 34;
      final s2 = sx * sx + sy * sy;
      if (s2 >= 7 * 7 && s2 <= 12 * 12) return 0xFFFFFF;
      return (r << 16) | (g << 8) | b;
  }
}

/// HSV → packed 0xRRGGBB. [h] in [0, 360), [s]/[v] in [0, 1].
int hsvToRgb(double h, double s, double v) {
  final c = v * s;
  final hh = h / 60.0;
  final xx = c * (1 - ((hh % 2) - 1).abs());
  double r, g, b;
  if (hh < 1) {
    (r, g, b) = (c, xx, 0);
  } else if (hh < 2) {
    (r, g, b) = (xx, c, 0);
  } else if (hh < 3) {
    (r, g, b) = (0, c, xx);
  } else if (hh < 4) {
    (r, g, b) = (0, xx, c);
  } else if (hh < 5) {
    (r, g, b) = (xx, 0, c);
  } else {
    (r, g, b) = (c, 0, xx);
  }
  final m = v - c;
  final ri = ((r + m) * 255).round().clamp(0, 255);
  final gi = ((g + m) * 255).round().clamp(0, 255);
  final bi = ((b + m) * 255).round().clamp(0, 255);
  return (ri << 16) | (gi << 8) | bi;
}
