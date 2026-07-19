// Pure pattern math for flood fills — no dart:ui / Flutter imports so it can
// run inside the flood-fill isolate (same pattern as flood_fill.dart).

/// How a flood fill paints the region: one flat color or a playful pattern
/// derived from the selected color.
enum FillPattern { solid, dots, stripes, rainbow }

const int _dotCell = 72;
const int _dotRadius = 18;
const int _stripeWidth = 56;
const int _rainbowCycle = 600;

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
      // Lightened stripe of the same color.
      final lr = r + ((255 - r) * 45) ~/ 100;
      final lg = g + ((255 - g) * 45) ~/ 100;
      final lb = b + ((255 - b) * 45) ~/ 100;
      return (lr << 16) | (lg << 8) | lb;
    case FillPattern.rainbow:
      final hue = ((x + y) % _rainbowCycle) * 360 / _rainbowCycle;
      return hsvToRgb(hue, 0.7, 1.0);
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
