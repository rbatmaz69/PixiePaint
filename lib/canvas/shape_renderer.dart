import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

import '../models/tool.dart';

/// Geometry and rendering for the drag-to-draw shape tool.
///
/// Shapes are anchored center-out: the finger lands on the center, the drag
/// distance is the radius — the same motion as placing a stamp, the easiest
/// motor task for small hands. Aspect is always locked.
class ShapeRenderer {
  /// Outline path of a shape inscribed in the circle (center, radius).
  /// The rainbow has no fill path — it is drawn as arcs in [drawShape].
  static Path shapePath(ShapeKind kind, Offset c, double r) {
    switch (kind) {
      case ShapeKind.circle:
        return Path()..addOval(Rect.fromCircle(center: c, radius: r));
      case ShapeKind.square:
        final side = r * 2 / sqrt2;
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: side, height: side),
            Radius.circular(side * 0.18),
          ));
      case ShapeKind.heart:
        return _heartPath(c, r);
      case ShapeKind.star:
        return _starPath(c, r);
      case ShapeKind.rainbow:
        return Path()
          ..addArc(Rect.fromCircle(center: c, radius: r), pi, pi);
    }
  }

  /// Two cubic béziers meeting in the bottom tip — a plump, kid-drawn heart.
  static Path _heartPath(Offset c, double r) {
    final w = r * 1.6;
    final h = r * 1.7;
    final top = c.dy - h * 0.32;
    final bottom = c.dy + h * 0.5;
    final path = Path()..moveTo(c.dx, bottom);
    path.cubicTo(c.dx - w * 0.62, c.dy + h * 0.02, c.dx - w * 0.55,
        top - h * 0.28, c.dx, top);
    path.cubicTo(c.dx + w * 0.55, top - h * 0.28, c.dx + w * 0.62,
        c.dy + h * 0.02, c.dx, bottom);
    path.close();
    return path;
  }

  /// Proper 5-point star, tip up.
  static Path _starPath(Offset c, double r) {
    const points = 5;
    final inner = r * 0.42;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : inner;
      final angle = -pi / 2 + i * pi / points;
      final p = c + Offset(cos(angle), sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  /// Fixed rainbow band colors, outermost first.
  static const List<Color> kRainbowColors = [
    Color(0xFFE53935),
    Color(0xFFFF9800),
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
  ];

  /// Draws a shape at full opacity onto [canvas]. Filled shapes get a
  /// slightly darker outline of the same hue so they pop off the paper —
  /// filled is the satisfying result for the 3–6 age group; outlines to
  /// color in already exist as coloring pages.
  static void drawShape(Canvas canvas, ShapeKind kind, Offset c, double r,
      Color color, double strokeWidth,
      {double opacity = 1.0}) {
    if (kind == ShapeKind.rainbow) {
      _drawRainbowArc(canvas, c, r, opacity);
      return;
    }
    final path = shapePath(kind, c, r);
    canvas.drawPath(
        path, Paint()..color = color.withValues(alpha: opacity));
    final hsl = HSLColor.fromColor(color);
    final outline = hsl
        .withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0))
        .toColor();
    canvas.drawPath(
        path,
        Paint()
          ..color = outline.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = strokeWidth.clamp(4.0, r * 0.25));
  }

  /// Six concentric stroked half-arcs, ignoring the selected color.
  static void _drawRainbowArc(
      Canvas canvas, Offset c, double r, double opacity) {
    final band = r / 9;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = band;
    for (var i = 0; i < kRainbowColors.length; i++) {
      final radius = r - i * band;
      if (radius <= band / 2) break;
      paint.color = kRainbowColors[i].withValues(alpha: opacity);
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: radius), pi, pi, false, paint);
    }
  }
}
