import 'dart:math';
import 'dart:ui' show Color;

import '../models/tool.dart';
import '../util/color_utils.dart';

/// The pens the dice may deal.
///
/// Only the ones that make a line the moment a finger lands. A sticker or
/// the letters tool needs a second choice before anything can be drawn at
/// all, and the whole point of the dice is that a child can start
/// immediately — the bucket and the eyedropper are out for the same reason:
/// neither draws.
const List<ToolKind> kSurprisePens = [
  ToolKind.brush,
  ToolKind.marker,
  ToolKind.crayon,
  ToolKind.rainbow,
  ToolKind.glitter,
  ToolKind.neon,
  ToolKind.trail,
  ToolKind.dotted,
  ToolKind.twin,
];

/// A pen and a colour out of the hat.
///
/// The colours are the paint row minus anything near-white: on white paper
/// that reads as a pen that does not work, and the dice must never look
/// broken.
({ToolKind tool, Color color}) dealSurprise([Random? random]) {
  final rng = random ?? Random();
  final colours = [
    for (final c in kPaletteColors)
      if (c.computeLuminance() < 0.8) c,
  ];
  return (
    tool: kSurprisePens[rng.nextInt(kSurprisePens.length)],
    color: colours[rng.nextInt(colours.length)],
  );
}
