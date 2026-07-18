import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import 'canvas_painter.dart';

/// The drawing surface: a fixed-resolution canvas scaled to fit the
/// available space. Pointer positions arrive in canvas coordinates because
/// the [Listener] sits inside the FittedBox transform.
class PaintingCanvas extends StatelessWidget {
  const PaintingCanvas({super.key, required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final w = controller.canvasWidth.toDouble();
    final h = controller.canvasHeight.toDouble();
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: w,
        height: h,
        child: Listener(
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
        ),
      ),
    );
  }
}
