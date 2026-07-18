import 'package:flutter/material.dart';

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

    final stroke = controller.activeStroke;
    final erasing = stroke?.kind == ToolKind.eraser;
    if (erasing) canvas.saveLayer(rect, Paint());
    final paintLayer = controller.paintLayer;
    if (paintLayer != null) {
      canvas.drawImage(paintLayer, Offset.zero, Paint());
    }
    if (stroke != null) StrokeRenderer.draw(canvas, stroke);
    if (erasing) canvas.restore();

    final lineArt = controller.lineArt;
    if (lineArt != null) {
      canvas.drawImage(lineArt, Offset.zero, Paint());
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) =>
      oldDelegate.controller != controller;
}
