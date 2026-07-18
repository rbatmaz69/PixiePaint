import 'package:flutter/material.dart';

import '../models/stamp.dart';
import '../models/tool.dart';
import 'canvas_controller.dart';
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
          kStampSizes[controller.sizeIndex]);
    }

    // Prefer the vector picture: it re-rasterizes under the viewport
    // transform, keeping outlines sharp at any zoom.
    final lineArtPicture = controller.lineArtPicture;
    if (lineArtPicture != null) {
      canvas.drawPicture(lineArtPicture);
    } else if (controller.lineArt != null) {
      canvas.drawImage(controller.lineArt!, Offset.zero, Paint());
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      oldDelegate.controller != controller;
}
