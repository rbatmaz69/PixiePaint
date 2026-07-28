import 'dart:typed_data';

/// How far a colour may be from the tapped one and still count as "the same
/// colour". Tighter than [kFillTolerance]: a fill has walls to stop it, the
/// wand has nothing but this number, and a child who taps a pink petal does
/// not expect the red hat to go too.
const int kWandTolerance = 24;

/// Below this alpha there is no paint, only paper. The wand never touches it
/// — that is what keeps a tap on an empty background from repainting the
/// whole picture.
const int kWandMinAlpha = 24;

/// Recolours every pixel of the paint layer that has the colour tapped at
/// [seedX]/[seedY].
///
/// The repair tool. A fill in the wrong colour three strokes ago used to cost
/// three undos — or, once the child had carried on painting, nothing at all:
/// the picture simply stayed wrong. The wand asks a different question than
/// the bucket. The bucket asks "what is this region", which needs walls; the
/// wand asks "what is this colour", which needs none, so it reaches the four
/// petals on the other side of the flower that were filled in the same wrong
/// blue.
///
/// [rgba] is the paint layer (premultiplied RGBA, w*h*4) and is modified in
/// place. Returns it, or null when nothing changed: a tap on bare paper, or
/// on a colour that already is the target.
///
/// Pure Dart, no dart:ui — safe to run via `Isolate.run`.
Uint8List? magicRecolor({
  required Uint8List rgba,
  required int width,
  required int height,
  required int seedX,
  required int seedY,
  required int toR,
  required int toG,
  required int toB,
  int tolerance = kWandTolerance,
  int minAlpha = kWandMinAlpha,
}) {
  if (seedX < 0 || seedY < 0 || seedX >= width || seedY >= height) return null;
  final seed = (seedY * width + seedX) * 4;
  final seedA = rgba[seed + 3];
  if (seedA < minAlpha) return null;

  // The buffer is premultiplied, so a soft stroke edge is the same colour at
  // a lower alpha *and* at proportionally lower channels. Comparing raw
  // bytes would match only the solid middle of a stroke and leave its edge
  // behind in the old colour — a halo around every repaired shape. So the
  // comparison happens in straight colour, undone per pixel.
  int straight(int v, int a) => a == 0 ? 0 : (v * 255 / a).round().clamp(0, 255);

  final fromR = straight(rgba[seed], seedA);
  final fromG = straight(rgba[seed + 1], seedA);
  final fromB = straight(rgba[seed + 2], seedA);

  if ((fromR - toR).abs() <= 8 &&
      (fromG - toG).abs() <= 8 &&
      (fromB - toB).abs() <= 8) {
    return null;
  }

  var changed = 0;
  for (var o = 0; o < rgba.length; o += 4) {
    final a = rgba[o + 3];
    if (a < minAlpha) continue;
    if (a == 255) {
      if ((rgba[o] - fromR).abs() > tolerance ||
          (rgba[o + 1] - fromG).abs() > tolerance ||
          (rgba[o + 2] - fromB).abs() > tolerance) {
        continue;
      }
      rgba[o] = toR;
      rgba[o + 1] = toG;
      rgba[o + 2] = toB;
    } else {
      if ((straight(rgba[o], a) - fromR).abs() > tolerance ||
          (straight(rgba[o + 1], a) - fromG).abs() > tolerance ||
          (straight(rgba[o + 2], a) - fromB).abs() > tolerance) {
        continue;
      }
      // Alpha is kept, so a soft edge stays soft and a stamp keeps its
      // shape. Only the hue moves.
      rgba[o] = (toR * a / 255).round();
      rgba[o + 1] = (toG * a / 255).round();
      rgba[o + 2] = (toB * a / 255).round();
    }
    changed++;
  }
  return changed == 0 ? null : rgba;
}
