/// The doodles on the paper: sparse hand-drawn stars, hearts and squiggles
/// scattered like faint pen marks.
///
/// Lives apart from [BlobBackground] since v8.4 because the canvas wants
/// them too — but standing still. Drifting marks behind a drawing hand are
/// the last thing a child painting a line needs, so there the painter is
/// built once with a fixed phase and never ticks.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'pixie_palette.dart';

enum DoodleKind { star, heart, circle, squiggle, sparkle }

class Doodle {
  const Doodle(this.kind, this.x, this.y, this.size, this.phase, this.rot);
  final DoodleKind kind;
  final double x, y; // fraction of the area
  final double size; // px
  final double phase; // 0..1
  final double rot; // base rotation, radians
}

/// Sparse hand-drawn doodles scattered like faint pen marks on the paper.
const kDoodles = [
  Doodle(DoodleKind.star, 0.08, 0.10, 34, 0.05, 0.3),
  Doodle(DoodleKind.squiggle, 0.30, 0.06, 44, 0.55, -0.2),
  Doodle(DoodleKind.heart, 0.68, 0.09, 28, 0.30, 0.25),
  Doodle(DoodleKind.sparkle, 0.92, 0.22, 26, 0.75, 0.0),
  Doodle(DoodleKind.circle, 0.05, 0.38, 30, 0.45, 0.0),
  Doodle(DoodleKind.sparkle, 0.45, 0.30, 24, 0.15, 0.5),
  Doodle(DoodleKind.star, 0.88, 0.48, 38, 0.90, -0.35),
  Doodle(DoodleKind.heart, 0.16, 0.62, 32, 0.65, -0.15),
  Doodle(DoodleKind.squiggle, 0.60, 0.58, 48, 0.20, 0.15),
  Doodle(DoodleKind.circle, 0.90, 0.80, 26, 0.40, 0.0),
  Doodle(DoodleKind.star, 0.38, 0.86, 30, 0.10, 0.4),
  Doodle(DoodleKind.sparkle, 0.70, 0.90, 28, 0.85, -0.25),
];

class DoodlePainter extends CustomPainter {
  const DoodlePainter(this.t, {this.alpha = 0.07});

  /// Position on the drift loop, 0..1. Hold it constant and the marks
  /// simply sit still.
  final double t;

  /// How dark the ink is. The default is the wash the home and picker
  /// screens use; the canvas asks for less, because whatever is drawn on
  /// top has to stay the loudest thing on screen.
  final double alpha;

  // Unit paths (fit roughly into -0.5..0.5), built once and reused.
  static final Path _star = _makeStar();
  static final Path _heart = _makeHeart();
  static final Path _circle = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.45));
  static final Path _squiggle = _makeSquiggle();
  static final Path _sparkle = _makeSparkle();

  static Path _makeStar() {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 0.5 : 0.22;
      final a = -pi / 2 + i * pi / 5;
      final p = Offset(cos(a), sin(a)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  static Path _makeHeart() {
    return Path()
      ..moveTo(0, 0.42)
      ..cubicTo(-0.52, 0.05, -0.46, -0.42, 0, -0.18)
      ..cubicTo(0.46, -0.42, 0.52, 0.05, 0, 0.42)
      ..close();
  }

  static Path _makeSquiggle() {
    return Path()
      ..moveTo(-0.5, 0)
      ..cubicTo(-0.3, -0.3, -0.15, 0.3, 0.05, 0)
      ..cubicTo(0.25, -0.3, 0.35, 0.3, 0.5, 0);
  }

  static Path _makeSparkle() {
    return Path()
      ..moveTo(0, -0.5)
      ..lineTo(0, 0.5)
      ..moveTo(-0.5, 0)
      ..lineTo(0.5, 0);
  }

  static Path _pathFor(DoodleKind kind) => switch (kind) {
        DoodleKind.star => _star,
        DoodleKind.heart => _heart,
        DoodleKind.circle => _circle,
        DoodleKind.squiggle => _squiggle,
        DoodleKind.sparkle => _sparkle,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PixiePalette.ink.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final d in kDoodles) {
      final angle = 2 * pi * (t + d.phase);
      final dx = (d.x + 0.015 * sin(angle)) * size.width;
      final dy = (d.y + 0.015 * cos(angle)) * size.height;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(d.rot + sin(angle) * 4 * pi / 180);
      // Unit paths are scaled by the canvas matrix, so the stroke width
      // must be divided back to stay a constant 2.5 px.
      canvas.scale(d.size);
      paint.strokeWidth = 2.5 / d.size;
      canvas.drawPath(_pathFor(d.kind), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(DoodlePainter old) => old.t != t || old.alpha != alpha;
}
