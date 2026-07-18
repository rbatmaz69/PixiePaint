import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'canvas_painter.dart';

/// The drawing surface at fixed canvas resolution. Sizing and zoom/pan are
/// applied by [CanvasViewport]; pointer positions arrive here already in
/// canvas coordinates because the ancestor Transform inverse-transforms
/// them for descendants.
class PaintingCanvas extends StatelessWidget {
  const PaintingCanvas({super.key, required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final w = controller.canvasWidth.toDouble();
    final h = controller.canvasHeight.toDouble();
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: controller.pointerDown,
      onPointerMove: controller.pointerMove,
      onPointerUp: controller.pointerUp,
      onPointerCancel: controller.pointerUp,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: CanvasPainter(controller),
          size: Size(w, h),
          isComplex: true,
        ),
      ),
    );
  }
}
