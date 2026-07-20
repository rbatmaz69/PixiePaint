import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

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
