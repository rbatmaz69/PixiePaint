import 'dart:math';
import 'dart:ui';

/// Magic-mirror symmetry: every gesture is repeated as N copies around the
/// canvas center. Pure math so the copy layout is unit-testable; the canvas
/// transform application lives here too so commit and preview can never
/// disagree.
///
/// Folds: 1 = off, 2 = butterfly (mirror across the vertical center axis),
/// 4 = flower, 6 = snowflake (rotational copies).
const List<int> kSymmetryFolds = [1, 2, 4, 6];

/// One copy of the gesture: rotated by [angle] radians around the center,
/// optionally mirrored across the vertical axis first.
class SymmetryCopy {
  final double angle;
  final bool mirror;

  const SymmetryCopy(this.angle, this.mirror);
}

/// The copies (including the identity) that make up an N-fold symmetry.
List<SymmetryCopy> symmetryCopies(int folds) {
  if (folds <= 1) return const [SymmetryCopy(0, false)];
  if (folds == 2) {
    // Butterfly: the original plus its mirror image, not a 180° turn.
    return const [SymmetryCopy(0, false), SymmetryCopy(0, true)];
  }
  return [for (var k = 0; k < folds; k++) SymmetryCopy(2 * pi * k / folds, false)];
}

/// Where a single point ends up under [copy] — used for stamps, whose glyph
/// must stay upright (transform the point, not the canvas).
Offset symmetryPoint(Offset p, Offset center, SymmetryCopy copy) {
  var q = copy.mirror ? Offset(2 * center.dx - p.dx, p.dy) : p;
  if (copy.angle != 0) {
    final d = q - center;
    final c = cos(copy.angle), s = sin(copy.angle);
    q = center + Offset(d.dx * c - d.dy * s, d.dx * s + d.dy * c);
  }
  return q;
}

/// Applies [copy] to the canvas; caller wraps in save/restore.
void applySymmetryTransform(Canvas canvas, Offset center, SymmetryCopy copy) {
  canvas.translate(center.dx, center.dy);
  if (copy.mirror) canvas.scale(-1, 1);
  if (copy.angle != 0) canvas.rotate(copy.angle);
  canvas.translate(-center.dx, -center.dy);
}
