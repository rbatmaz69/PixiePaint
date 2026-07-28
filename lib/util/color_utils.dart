import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

/// The sixteen colors of the paint row.
///
/// Content, not surface — this is what a child paints *with*, and it
/// deliberately does not come from `PixiePalette`. It lives here rather
/// than beside the palette widget because the canvas needs it too, and a
/// controller should not have to import a widget to know its own default.
const List<Color> kPaletteColors = [
  Color(0xFFE53935), // rot
  Color(0xFFFF7043), // orange
  Color(0xFFFFC107), // gelb
  Color(0xFF9CCC65), // hellgrün
  Color(0xFF43A047), // grün
  Color(0xFF26A69A), // türkis
  Color(0xFF29B6F6), // hellblau
  Color(0xFF1E88E5), // blau
  Color(0xFF5E35B1), // lila
  Color(0xFFEC407A), // pink
  Color(0xFFF8BBD0), // rosa
  Color(0xFF8D6E63), // braun
  Color(0xFFF1C27D), // hautton
  Color(0xFF90A4AE), // grau
  Color(0xFF000000), // schwarz
  Color(0xFFFFFFFF), // weiß
];

/// Hues of the big color grid, one column each (red → pink).
const List<double> kGridHues = [0, 30, 55, 120, 175, 210, 265, 320];

/// Lightness per row, light on top so the grid reads like a rainbow
/// fading into the dark.
const List<double> kGridLightness = [0.85, 0.70, 0.55, 0.40, 0.28];

/// Bottom row of the grid: skin tones, browns and grays that HSL rows
/// can't produce.
const List<Color> kGridNeutrals = [
  Color(0xFFFFFFFF),
  Color(0xFFF1C27D),
  Color(0xFFC68642),
  Color(0xFF8D6E63),
  Color(0xFF5D4037),
  Color(0xFF90A4AE),
  Color(0xFF455A64),
  Color(0xFF000000),
];

/// The kid color grid: [kGridLightness] rows of [kGridHues] colors plus the
/// neutrals row. No hex inputs, no wheels — just a big organized rainbow.
List<List<Color>> kidColorGrid() => [
      for (final l in kGridLightness)
        [
          for (final h in kGridHues)
            HSLColor.fromAHSL(1, h, 0.85, l).toColor(),
        ],
      kGridNeutrals,
    ];

/// Light colors need a subtle border to stay visible on light surfaces —
/// same rule the palette uses for white.
bool needsBorder(Color c) => c.computeLuminance() > 0.7;

/// Which of the sixteen names each grid column borrows, in the order of
/// [kGridHues]: rot · orange · gelb · grün · türkis · blau · lila · pink.
///
/// The grid is *generated*, so its colors never have to be guessed at — a
/// swatch knows which hue it was built from, and the whole column shares
/// that name honestly. Five reds in a column is five reds; it is only the
/// exact shade that goes unsaid, and no name is ever wrong.
const List<int> kGridHueNames = [0, 1, 2, 4, 5, 7, 8, 9];

/// The same for the neutrals row, in the order of [kGridNeutrals]:
/// weiß · hautton · hautton · braun · braun · grau · grau · schwarz.
const List<int> kGridNeutralNames = [15, 12, 12, 11, 11, 13, 13, 14];

/// Index into [kPaletteColors] of the color [c] comes closest to.
///
/// For what *cannot* be traced back to a column: the recently-used row and
/// anything the eyedropper lifted off the picture. Hue leads, because a
/// name is a family and not a shade — plain RGB or Lab distance both send
/// a pale blue to "grau", which is perceptually defensible and useless to
/// a child. Saturation and lightness only break ties, which is what tells
/// rosa from pink and braun from orange.
///
/// A palette color is its own nearest neighbour at distance zero, so exact
/// matches still answer exactly.
int nearestPaletteIndex(Color c) {
  final a = HSLColor.fromColor(c);
  var best = 0;
  var bestDistance = double.infinity;
  for (var i = 0; i < kPaletteColors.length; i++) {
    final b = HSLColor.fromColor(kPaletteColors[i]);
    var dh = (a.hue - b.hue).abs();
    if (dh > 180) dh = 360 - dh;
    // Weighted by the *lesser* of the two saturations: hue means nothing
    // on a grey, so grey stops competing for colorful names and vice versa.
    final d = (dh / 180) * 3.0 * math.min(a.saturation, b.saturation) +
        (a.saturation - b.saturation).abs() * 0.8 +
        (a.lightness - b.lightness).abs() * 1.2;
    if (d < bestDistance) {
      bestDistance = d;
      best = i;
    }
  }
  return best;
}

// ---------------------------------------------------------------- mixing

/// Anchors of the paint colour wheel against the screen colour wheel, as
/// (RGB hue, artistic hue) pairs.
///
/// Red, yellow and blue are opposite thirds on the wheel a child meets in
/// every paint box; on a screen the primaries are red, *green* and blue and
/// yellow is squeezed into a sixth of the circle. Mixing on the screen wheel
/// is what produces the answer every adult remembers being wrong as a kid:
/// blue and yellow give grey. So hues are carried over to the paint wheel,
/// mixed there, and carried back.
const List<(double, double)> _hueAnchors = [
  (0, 0), // red
  (30, 60), // orange
  (60, 120), // yellow
  (120, 180), // green
  (240, 240), // blue
  (300, 300), // purple
  (360, 360),
];

double _mapHue(double hue, {required bool toArtistic}) {
  final h = hue % 360;
  for (var i = 0; i < _hueAnchors.length - 1; i++) {
    final from = toArtistic ? _hueAnchors[i].$1 : _hueAnchors[i].$2;
    final to = toArtistic ? _hueAnchors[i + 1].$1 : _hueAnchors[i + 1].$2;
    if (h >= from && h <= to) {
      final t = to == from ? 0.0 : (h - from) / (to - from);
      final a = toArtistic ? _hueAnchors[i].$2 : _hueAnchors[i].$1;
      final b = toArtistic ? _hueAnchors[i + 1].$2 : _hueAnchors[i + 1].$1;
      return a + (b - a) * t;
    }
  }
  return h;
}

/// Below this a colour has no hue worth mixing — it is white, black or a
/// grey, and what it contributes is lightness.
const double _greyish = 0.08;

/// What you get when you stir [a] and [b] together on a palette.
///
/// Deliberately not the average of two RGB values: that is light mixing, and
/// it answers blue + yellow with grey. This mixes on the paint wheel (see
/// [_hueAnchors]), so blue and yellow give green, red and yellow orange, red
/// and blue purple — the answers a child can check against a paint box.
///
/// Two further things real paint does and arithmetic does not:
/// * a grey, white or black partner moves the *lightness* and leaves the hue
///   alone, so red and white is pink rather than something rotated;
/// * two colours far apart on the wheel dull each other. Mixing everything
///   ends in mud, which is the honest answer and also the funny one.
Color mixPaint(Color a, Color b) {
  final x = HSLColor.fromColor(a);
  final y = HSLColor.fromColor(b);
  final lightness = (x.lightness + y.lightness) / 2;

  if (x.saturation < _greyish && y.saturation < _greyish) {
    return HSLColor.fromAHSL(1, 0, 0, lightness).toColor();
  }
  // One of them carries no hue: it tints or shades the other.
  if (x.saturation < _greyish || y.saturation < _greyish) {
    final coloured = x.saturation < _greyish ? y : x;
    return HSLColor.fromAHSL(
            1, coloured.hue, coloured.saturation * 0.75, lightness)
        .toColor();
  }

  final ax = _mapHue(x.hue, toArtistic: true);
  final ay = _mapHue(y.hue, toArtistic: true);
  var delta = ay - ax;
  // Round the short way: red and purple meet at magenta, not at green.
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  final mixed = _mapHue(ax + delta / 2, toArtistic: false);

  final apart = delta.abs() / 180;
  final saturation =
      ((x.saturation + y.saturation) / 2 * (1 - 0.45 * apart)).clamp(0.0, 1.0);
  return HSLColor.fromAHSL(1, mixed % 360, saturation, lightness).toColor();
}

/// Most-recent-first list of ARGB values: dedups, caps at [max].
List<int> pushRecentArgb(List<int> recents, int argb, {int max = 8}) {
  final next = [argb, ...recents.where((v) => v != argb)];
  return next.length > max ? next.sublist(0, max) : next;
}

/// Samples the pixel at (x, y) from a rawRgba buffer of a [width]-wide
/// image. Coordinates are clamped to the buffer. Used by the eyedropper.
Color colorAtRgba(Uint8List rgba, int width, int height, int x, int y) {
  final cx = x.clamp(0, width - 1);
  final cy = y.clamp(0, height - 1);
  final i = (cy * width + cx) * 4;
  return Color.fromARGB(rgba[i + 3], rgba[i], rgba[i + 1], rgba[i + 2]);
}
