import 'package:flutter/material.dart';

import '../models/tool.dart';
import '../ui/pixie_palette.dart';
import '../util/settings.dart';
import 'canvas_controller.dart';
import 'canvas_painter.dart';

/// The lens: a bubble that follows the finger and shows the paper underneath
/// it, enlarged.
///
/// The problem it solves is the oldest one in finger painting — the hand
/// covers exactly the spot it is working on. An adult compensates by tilting
/// their wrist; a four-year-old colouring the eye of a butterfly simply
/// cannot see whether they are on the line or past it. It hits tracing and
/// the numbered pictures hardest, because both are about *where* a mark
/// lands rather than what it looks like.
///
/// Lives INSIDE the transformed canvas space (see PaintingCanvas), like the
/// two burst overlays, so its coordinates are canvas pixels and it grows and
/// shrinks with the zoom instead of fighting it.
///
/// **Cost:** the picture is drawn a second time inside the lens clip while a
/// stroke is in progress. Images and display lists are cheap to repeat; a
/// long glitter stroke is not, and this is the one place in the app that
/// pays for a frame twice. That is why the lens is a setting a parent can
/// switch off, and why it shows only while a finger is actually down.
class MagnifierOverlay extends StatelessWidget {
  const MagnifierOverlay({super.key, required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: MagnifierPainter(controller));
}

/// How much bigger the lens shows the paper. Enough that a line has a visible
/// inside and outside, not so much that the child loses the context around
/// what they are working on.
const double kMagnifierZoom = 2.5;

/// Radius of the lens in canvas pixels, as a share of the canvas width — the
/// app has two canvas sizes and the lens should cover the same *fraction* of
/// the paper in both.
double magnifierRadius(double canvasWidth) => canvasWidth * 0.085;

/// Where the bubble sits for a finger at [pos].
///
/// Above the finger by default, which is where the hand is not. Near the top
/// edge it flips below instead of sliding under the fingertip — a lens that
/// creeps over the spot it is showing is worse than no lens. Horizontally it
/// is kept fully on the paper, because half a bubble hanging off the edge
/// reads as a drawing mistake.
Offset magnifierCenter({
  required Offset pos,
  required Size canvas,
  required double radius,
}) {
  final margin = radius * 0.14;
  final lift = radius * 1.95;
  final above = pos.dy - lift;
  final below = pos.dy + lift;
  final dy = above - radius >= margin ? above : below;
  return Offset(
    _within(pos.dx, radius + margin, canvas.width - radius - margin),
    _within(dy, radius + margin, canvas.height - radius - margin),
  );
}

/// [v] held between [low] and [high], and centred if the two have crossed.
///
/// `clamp` throws when the lower bound is above the upper one, and a throw
/// here would take down a paint pass rather than misplace a bubble. It
/// cannot happen on a 4:3 canvas — but the lens is drawn on every sample of
/// every stroke, and that is the wrong place for an assumption about canvas
/// shapes to be resting on.
double _within(double v, double low, double high) =>
    low > high ? (low + high) / 2 : v.clamp(low, high);

class MagnifierPainter extends CustomPainter {
  MagnifierPainter(this.controller) : super(repaint: controller.repaint);

  final CanvasController controller;

  @override
  void paint(Canvas canvas, Size size) {
    if (!Settings.instance.magnifier) return;
    final pos = controller.livePoint;
    if (pos == null) return;

    final radius = magnifierRadius(size.width);
    final center = magnifierCenter(pos: pos, canvas: size, radius: radius);
    final rim = radius * 0.07;

    canvas.drawCircle(
        center + Offset(0, rim),
        radius + rim,
        Paint()
          ..color = Colors.black26
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, rim * 2));
    canvas.drawCircle(center, radius + rim, Paint()..color = Colors.white);

    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    // Put the point under the finger in the middle of the bubble, blown up
    // around it.
    canvas.translate(center.dx, center.dy);
    canvas.scale(kMagnifierZoom);
    canvas.translate(-pos.dx, -pos.dy);
    paintCanvasPicture(canvas, size, controller);
    canvas.restore();

    _drawFootprint(canvas, center, radius);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim
          ..color = PixiePalette.ink.withValues(alpha: 0.15));
  }

  /// The ring in the middle of the lens is how wide this brush paints —
  /// the second question a child has after "am I on the line", and the one
  /// the size slider only answers in the abstract.
  ///
  /// Only the tools that draw *from* the point get it. A sticker or a shape
  /// is placed, not dragged, and its own live preview is already in the lens.
  void _drawFootprint(Canvas canvas, Offset center, double radius) {
    const drawn = {
      ToolKind.stamp,
      ToolKind.text,
      ToolKind.shape,
      ToolKind.fill,
      ToolKind.eyedropper,
      ToolKind.wand,
    };
    if (drawn.contains(controller.tool)) return;
    final r = (controller.brushSize / 2 * kMagnifierZoom).clamp(4.0, radius * 0.8);
    canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.02
          ..color = Colors.white70);
    canvas.drawCircle(
        center,
        r + radius * 0.02,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.012
          ..color = Colors.black26);
  }

  @override
  bool shouldRepaint(MagnifierPainter oldDelegate) =>
      oldDelegate.controller != controller;
}
