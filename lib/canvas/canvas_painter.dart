import 'package:flutter/material.dart';

import '../models/tool.dart';
import 'canvas_controller.dart';
import 'shape_renderer.dart';
import 'stroke_renderer.dart';

class CanvasPainter extends CustomPainter {
  CanvasPainter(this.controller) : super(repaint: controller.repaint);

  final CanvasController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Colors.white);

    // Photo background sits below the eraser saveLayer so erasing can
    // never remove it.
    final background = controller.backgroundImage;
    if (background != null) {
      canvas.drawImage(background, Offset.zero, Paint());
    }

    final stroke = controller.activeStroke;
    final erasing = stroke?.kind == ToolKind.eraser;
    if (erasing) canvas.saveLayer(rect, Paint());
    final paintLayer = controller.paintLayer;
    if (paintLayer != null) {
      canvas.drawImage(paintLayer, Offset.zero, Paint());
    }
    if (stroke != null) StrokeRenderer.draw(canvas, stroke);
    if (erasing) canvas.restore();

    final pendingStamp = controller.pendingStampPos;
    if (pendingStamp != null) {
      StrokeRenderer.drawStamp(canvas, controller.stampEmoji, pendingStamp,
          stampSizeFor(controller.brushSize));
    }

    // Semi-transparent live preview of the shape being dragged out.
    final shapeCenter = controller.shapeCenter;
    if (shapeCenter != null) {
      ShapeRenderer.drawShape(canvas, controller.shapeKind, shapeCenter,
          controller.shapeRadius, controller.color, controller.brushSize * 0.4,
          opacity: 0.7);
    }

    // Prefer the vector picture: it re-rasterizes under the viewport
    // transform, keeping outlines sharp at any zoom.
    final lineArtPicture = controller.lineArtPicture;
    if (lineArtPicture != null) {
      canvas.drawPicture(lineArtPicture);
    } else if (controller.lineArt != null) {
      canvas.drawImage(controller.lineArt!, Offset.zero, Paint());
    }

    final pickPos = controller.pendingPickPos;
    if (pickPos != null) {
      _drawPickLoupe(canvas, pickPos, controller.pickedPreview);
    }
  }

  /// Eyedropper loupe: a white-ringed bubble above the finger showing the
  /// color underneath, plus a small dot marking the sampled pixel.
  void _drawPickLoupe(Canvas canvas, Offset pos, Color? picked) {
    final color = picked ?? Colors.white;
    final center = pos - const Offset(0, 140);
    canvas.drawCircle(
        center + const Offset(0, 6),
        58,
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(center, 58, Paint()..color = Colors.white);
    canvas.drawCircle(center, 48, Paint()..color = color);
    canvas.drawCircle(
        pos,
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawCircle(
        pos,
        9,
        Paint()
          ..color = Colors.black38
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      oldDelegate.controller != controller;
}
