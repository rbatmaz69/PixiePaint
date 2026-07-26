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
