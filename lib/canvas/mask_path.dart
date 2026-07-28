import 'dart:math';
import 'dart:ui';

import '../models/mask.dart';
import '../models/tool.dart';
import '../ui/pixie_palette.dart';
import 'shape_renderer.dart';

/// Half-width of the strip, as a share of its length. Wide enough to paint
/// a road or a rooftop through, narrow enough that it still reads as tape
/// rather than as a rectangle.
const double _stripThickness = 0.22;

/// The outline of the tape itself, wherever it sits.
Path tapeShapePath(Mask mask) {
  final c = Offset(mask.x, mask.y);
  if (mask.kind == ShapeKind.line) {
    // The four corners straight out of the drag: along it for the length,
    // across it for the width. Cheaper to read than a transform, and the
    // strip is the one motif whose direction is the whole point.
    final half = max(mask.radius * _stripThickness, 24.0);
    final along = Offset(cos(mask.angle), sin(mask.angle)) * mask.radius;
    final across = Offset(-sin(mask.angle), cos(mask.angle)) * half;
    final path = Path()..moveTo((c - along - across).dx, (c - along - across).dy);
    for (final corner in [c + along - across, c + along + across, c - along + across]) {
      path.lineTo(corner.dx, corner.dy);
    }
    return path..close();
  }
  // An open motif has no inside to protect; the circle is the safe stand-in
  // (see Mask.fromJson — a tape from a newer version can name anything).
  final kind =
      ShapeRenderer.isOpen(mask.kind) ? ShapeKind.circle : mask.kind;
  return ShapeRenderer.shapePath(kind, c, mask.radius);
}

/// What paint is allowed to reach: the tape's own shape, or everything
/// except it.
Path maskClipPath(Mask mask, Size canvas) {
  final shape = tapeShapePath(mask);
  if (!mask.inverted) return shape;
  return Path.combine(PathOperation.difference,
      Path()..addRect(Offset.zero & canvas), shape);
}

/// Draws the tape onto the paper: a translucent sheet with a dashed edge.
///
/// It is a guide, never paint — nothing bakes it into the layer, so exports,
/// thumbnails and the saved picture never see it, exactly like the tracing
/// guide. What the child sees is that something is lying *on* their picture
/// and can be pulled off again.
void drawTape(Canvas canvas, Mask mask, Size canvasSize) {
  final path = tapeShapePath(mask);
  // The protected side is the one that gets covered — with the tape turned
  // around, the sheet is everything *but* the shape, so the picture keeps
  // saying which part is being kept clean.
  final covered = mask.inverted
      ? Path.combine(PathOperation.difference,
          Path()..addRect(Offset.zero & canvasSize), path)
      : path;
  canvas.drawPath(
      covered,
      Paint()..color = PixiePalette.sunshine.withValues(alpha: 0.16));
  _dashed(canvas, path, canvasSize);
}

/// The edge, as a run of dashes — the one line on the paper that has to read
/// as "not part of the picture".
void _dashed(Canvas canvas, Path path, Size canvasSize) {
  final dash = (canvasSize.width * 0.014).clamp(12.0, 40.0);
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = (canvasSize.width * 0.004).clamp(2.0, 8.0)
    ..strokeCap = StrokeCap.round
    ..color = PixiePalette.tangerine.withValues(alpha: 0.85);
  for (final metric in path.computeMetrics()) {
    var d = 0.0;
    while (d < metric.length) {
      final end = min(d + dash, metric.length);
      canvas.drawPath(metric.extractPath(d, end), paint);
      d = end + dash;
    }
  }
}
