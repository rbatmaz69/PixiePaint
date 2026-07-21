import 'dart:math';

import 'package:flutter/material.dart';

import '../models/tool.dart';
import 'canvas_controller.dart';
import 'shape_renderer.dart';
import 'stroke_renderer.dart';
import 'symmetry.dart';

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

    // Trace guide under the paint layer and outside the eraser saveLayer —
    // the kid draws over it, the eraser can't remove it, exports never see
    // it (compose reads only background/paint/lineArt).
    final traceGuide = controller.traceGuide;
    if (traceGuide != null) {
      canvas.drawPicture(traceGuide);
    }

    final stroke = controller.activeStroke;
    final erasing = stroke?.kind == ToolKind.eraser;
    if (erasing) canvas.saveLayer(rect, Paint());
    final paintLayer = controller.paintLayer;
    if (paintLayer != null) {
      canvas.drawImage(paintLayer, Offset.zero, Paint());
    }
    if (stroke != null) {
      for (final copy in symmetryCopies(controller.symmetryFolds)) {
        canvas.save();
        applySymmetryTransform(canvas, controller.canvasCenter, copy);
        StrokeRenderer.draw(canvas, stroke);
        canvas.restore();
      }
    }
    if (erasing) canvas.restore();

    if (controller.symmetryFolds > 1) {
      _drawSymmetryGuides(canvas, size);
    }

    final pendingStamp = controller.pendingStampPos;
    if (pendingStamp != null) {
      for (final copy in symmetryCopies(controller.symmetryFolds)) {
        final p = symmetryPoint(pendingStamp, controller.canvasCenter, copy);
        final stampImage = controller.stampImage;
        if (stampImage != null) {
          StrokeRenderer.drawImageStamp(
              canvas, stampImage, p, stampSizeFor(controller.brushSize));
        } else {
          StrokeRenderer.drawStamp(canvas, controller.stampEmoji, p,
              stampSizeFor(controller.brushSize));
        }
      }
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

  /// Faint spokes through the center showing where the magic-mirror copies
  /// land: one vertical axis for the butterfly mirror, N spokes otherwise.
  void _drawSymmetryGuides(Canvas canvas, Size size) {
    final folds = controller.symmetryFolds;
    final center = controller.canvasCenter;
    final paint = Paint()
      ..color = const Color(0xFF7C6BF0).withValues(alpha: 0.18)
      ..strokeWidth = 3;
    final reach = size.longestSide;
    if (folds == 2) {
      canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paint);
      return;
    }
    for (var k = 0; k < folds; k++) {
      final a = 2 * pi * k / folds - pi / 2;
      canvas.drawLine(
          center, center + Offset(cos(a), sin(a)) * reach, paint);
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
