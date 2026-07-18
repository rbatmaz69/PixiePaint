import 'dart:math';
import 'dart:ui';

import '../models/tool.dart';
import 'stroke.dart';

/// Draws a stroke onto a canvas in canvas coordinates.
///
/// Eraser strokes use [BlendMode.clear]; the caller must wrap the paint
/// layer and the eraser stroke in a `saveLayer` scope for that to work.
class StrokeRenderer {
  static void draw(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    switch (stroke.kind) {
      case ToolKind.brush:
        _drawVariableWidth(canvas, stroke, _paintFor(stroke));
      case ToolKind.eraser:
        final paint = _paintFor(stroke)..blendMode = BlendMode.clear;
        _drawVariableWidth(canvas, stroke, paint, widthScale: 1.6);
      case ToolKind.marker:
        _drawMarker(canvas, stroke);
      case ToolKind.crayon:
        _drawCrayon(canvas, stroke);
      case ToolKind.fill:
        break; // fills are not strokes
    }
  }

  static Paint _paintFor(Stroke stroke) => Paint()
    ..color = stroke.color
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  static double _width(Stroke stroke, double pressure) =>
      stroke.baseWidth * lerpDouble(0.5, 1.7, pressure.clamp(0.0, 1.0))!;

  /// Pressure-sensitive: each segment gets its own width. Round caps make
  /// the joints seamless. Full-opacity tools only (overlaps are invisible).
  static void _drawVariableWidth(Canvas canvas, Stroke stroke, Paint paint,
      {double widthScale = 1.0}) {
    final pts = stroke.points;
    if (pts.length == 1) {
      canvas.drawCircle(
          pts.first.pos,
          _width(stroke, pts.first.pressure) * widthScale / 2,
          Paint()
            ..color = paint.color
            ..blendMode = paint.blendMode);
      return;
    }
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      paint.strokeWidth =
          _width(stroke, (a.pressure + b.pressure) / 2) * widthScale;
      canvas.drawLine(a.pos, b.pos, paint);
    }
  }

  /// Semi-transparent constant width. Rendered as ONE smoothed path so the
  /// stroke never darkens where it overlaps itself.
  static void _drawMarker(Canvas canvas, Stroke stroke) {
    final paint = _paintFor(stroke)
      ..color = stroke.color.withValues(alpha: 0.55)
      ..strokeCap = StrokeCap.square
      ..strokeWidth = stroke.baseWidth * 1.5;
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first.pos, stroke.baseWidth * 0.75,
          Paint()..color = paint.color);
      return;
    }
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

  /// Waxy look: three jittered semi-transparent passes with a slight blur.
  /// Jitter comes from the stroke's fixed seed so the preview doesn't
  /// flicker between frames.
  static void _drawCrayon(Canvas canvas, Stroke stroke) {
    final rng = Random(stroke.seed);
    for (var pass = 0; pass < 3; pass++) {
      final dx = (rng.nextDouble() - 0.5) * stroke.baseWidth * 0.35;
      final dy = (rng.nextDouble() - 0.5) * stroke.baseWidth * 0.35;
      final paint = _paintFor(stroke)
        ..color = stroke.color.withValues(alpha: 0.30)
        ..strokeWidth = stroke.baseWidth * (0.8 + rng.nextDouble() * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      if (stroke.points.length == 1) {
        canvas.drawCircle(
            stroke.points.first.pos + Offset(dx, dy),
            stroke.baseWidth / 2,
            Paint()
              ..color = paint.color
              ..maskFilter = paint.maskFilter);
        continue;
      }
      canvas.save();
      canvas.translate(dx, dy);
      canvas.drawPath(_smoothPath(stroke.points), paint);
      canvas.restore();
    }
  }

  /// Quadratic-bezier midpoint smoothing over the raw pointer polyline.
  static Path _smoothPath(List<StrokePoint> pts) {
    final path = Path()..moveTo(pts.first.pos.dx, pts.first.pos.dy);
    if (pts.length == 2) {
      path.lineTo(pts[1].pos.dx, pts[1].pos.dy);
      return path;
    }
    for (var i = 1; i < pts.length - 1; i++) {
      final p = pts[i].pos;
      final next = pts[i + 1].pos;
      final mid = Offset((p.dx + next.dx) / 2, (p.dy + next.dy) / 2);
      path.quadraticBezierTo(p.dx, p.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.pos.dx, pts.last.pos.dy);
    return path;
  }
}
