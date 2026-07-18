import 'dart:math';
import 'dart:ui' hide TextStyle;

import 'package:flutter/painting.dart'
    show HSVColor, TextPainter, TextSpan, TextStyle;

import '../models/tool.dart';
import 'stroke.dart';

class GlitterDot {
  final Offset pos;
  final double radius;
  final int colorIndex; // 0 white, 1 stroke color, 2 gold
  final bool star;

  const GlitterDot({
    required this.pos,
    required this.radius,
    required this.colorIndex,
    required this.star,
  });
}

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
      case ToolKind.rainbow:
        _drawRainbow(canvas, stroke);
      case ToolKind.glitter:
        _drawGlitter(canvas, stroke);
      case ToolKind.neon:
        _drawNeon(canvas, stroke);
      case ToolKind.fill:
      case ToolKind.stamp:
        break; // not stroke-based
    }
  }

  /// Renders an emoji stamp centered at [center]. Used for both the live
  /// preview (CanvasPainter) and the commit (CanvasController).
  static void drawStamp(
      Canvas canvas, String emoji, Offset center, double size) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    tp.dispose();
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

  /// Hue (0..360) at a given distance along a rainbow stroke. Pure so the
  /// preview is stable frame-to-frame and the cycle is unit-testable.
  static double hueAt(double distance, int seed) =>
      ((seed % 360) + distance / kRainbowCycleLength * 360) % 360;

  static const double kRainbowCycleLength = 500; // canvas px per full cycle

  /// Pressure-sensitive segments whose hue advances with the distance
  /// travelled. Ignores the selected color.
  static void _drawRainbow(Canvas canvas, Stroke stroke) {
    final pts = stroke.points;
    Color colorAt(double dist) =>
        HSVColor.fromAHSV(1, hueAt(dist, stroke.seed), 0.85, 1).toColor();
    if (pts.length == 1) {
      canvas.drawCircle(pts.first.pos,
          _width(stroke, pts.first.pressure) / 2, Paint()..color = colorAt(0));
      return;
    }
    final paint = _paintFor(stroke);
    var dist = 0.0;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      dist += (b.pos - a.pos).distance;
      paint
        ..color = colorAt(dist)
        ..strokeWidth = _width(stroke, (a.pressure + b.pressure) / 2);
      canvas.drawLine(a.pos, b.pos, paint);
    }
  }

  static const int kMaxGlitterDots = 1500;
  static const Color _gold = Color(0xFFFFE082);

  /// Sparkle positions along the stroke. The RNG is consumed strictly
  /// segment-by-segment, so the dots for a point prefix never change as new
  /// points are appended — the live preview doesn't flicker.
  static List<GlitterDot> glitterDots(
      List<StrokePoint> pts, double baseWidth, int seed) {
    final rng = Random(seed);
    final dots = <GlitterDot>[];
    for (var i = 1; i < pts.length && dots.length < kMaxGlitterDots; i++) {
      final a = pts[i - 1].pos;
      final b = pts[i].pos;
      final seg = b - a;
      final len = seg.distance;
      final n = (len / 12).ceil().clamp(1, 4);
      final normal = len > 0
          ? Offset(-seg.dy / len, seg.dx / len)
          : const Offset(0, 1);
      for (var k = 0; k < n && dots.length < kMaxGlitterDots; k++) {
        final t = rng.nextDouble();
        final side = (rng.nextDouble() - 0.5) * 2 * baseWidth;
        dots.add(GlitterDot(
          pos: a + seg * t + normal * side,
          radius: 1.5 + rng.nextDouble() * 2.5,
          colorIndex: rng.nextInt(3),
          star: rng.nextDouble() < 0.25,
        ));
      }
    }
    return dots;
  }

  static void _drawGlitter(Canvas canvas, Stroke stroke) {
    // Thin base trail in the selected color.
    if (stroke.points.length > 1) {
      final base = _paintFor(stroke)
        ..color = stroke.color.withValues(alpha: 0.5)
        ..strokeWidth = stroke.baseWidth * 0.35;
      canvas.drawPath(_smoothPath(stroke.points), base);
    }
    final colors = [const Color(0xFFFFFFFF), stroke.color, _gold];
    for (final dot in
        glitterDots(stroke.points, stroke.baseWidth, stroke.seed)) {
      final paint = Paint()..color = colors[dot.colorIndex];
      if (dot.star) {
        canvas.drawPath(_starPath(dot.pos, dot.radius * 2.2), paint);
      } else {
        canvas.drawCircle(dot.pos, dot.radius, paint);
      }
    }
  }

  /// Simple 4-point sparkle star.
  static Path _starPath(Offset c, double r) {
    final inner = r * 0.35;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + inner, c.dy - inner)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + inner, c.dy + inner)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - inner, c.dy + inner)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - inner, c.dy - inner)
      ..close();
  }

  /// Bright core over a blurred glow — two passes over one smoothed path
  /// (constant width, so no self-overlap artifacts).
  static void _drawNeon(Canvas canvas, Stroke stroke) {
    if (stroke.points.length == 1) {
      final p = stroke.points.first.pos;
      canvas.drawCircle(
          p,
          stroke.baseWidth * 1.2,
          Paint()
            ..color = stroke.color.withValues(alpha: 0.85)
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, stroke.baseWidth * 0.5));
      canvas.drawCircle(p, stroke.baseWidth * 0.45,
          Paint()..color = Color.lerp(stroke.color, const Color(0xFFFFFFFF), 0.65)!);
      return;
    }
    final path = _smoothPath(stroke.points);
    final glow = _paintFor(stroke)
      ..color = stroke.color.withValues(alpha: 0.85)
      ..strokeWidth = stroke.baseWidth * 2.4
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.baseWidth * 0.5);
    canvas.drawPath(path, glow);
    final core = _paintFor(stroke)
      ..color = Color.lerp(stroke.color, const Color(0xFFFFFFFF), 0.65)!
      ..strokeWidth = stroke.baseWidth * 0.9;
    canvas.drawPath(path, core);
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
