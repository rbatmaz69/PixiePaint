import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'canvas_controller.dart';
import 'canvas_painter.dart';
import 'fill_burst.dart';
import 'stamp_burst.dart';

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
    // The painting is pixels, not content a screen reader can describe, and
    // the burst overlays are pure decoration. Announced as one named
    // surface so it can be found and skipped, never walked through.
    return Semantics(
      label: context.l10n.canvasArea,
      container: true,
      excludeSemantics: true,
      child: _surface(w, h),
    );
  }

  Widget _surface(double w, double h) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: controller.pointerDown,
      onPointerMove: controller.pointerMove,
      onPointerUp: controller.pointerUp,
      onPointerCancel: controller.pointerUp,
      child: Stack(
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: CanvasPainter(controller),
              size: Size(w, h),
              isComplex: true,
            ),
          ),
          // Burst effects live in canvas space so they scale with zoom —
          // and stay OUTSIDE the canvas RepaintBoundary above.
          Positioned.fill(
            child: IgnorePointer(
              child: FillBurstOverlay(controller: controller),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: StampBurstOverlay(controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}
