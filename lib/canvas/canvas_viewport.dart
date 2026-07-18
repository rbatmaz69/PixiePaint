import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'canvas_controller.dart';

const double kMaxZoom = 4.0;

/// Keeps the canvas inside the viewport: centers an axis that fits,
/// clamps one that overflows. Pure function for unit testing.
Offset clampTranslation(Offset t, Size viewport, Size canvas, double scale) {
  double clampAxis(double tv, double v, double c) {
    final scaled = c * scale;
    if (scaled <= v) return (v - scaled) / 2;
    return tv.clamp(v - scaled, 0.0);
  }

  return Offset(
    clampAxis(t.dx, viewport.width, canvas.width),
    clampAxis(t.dy, viewport.height, canvas.height),
  );
}

/// Zoom/pan state of the canvas viewport. `pan` is the deviation (in
/// viewport px) from the centered contain-fit position.
class CanvasViewportController extends ChangeNotifier {
  double zoom = 1.0;
  Offset pan = Offset.zero;

  bool get isZoomed => zoom > 1.001;

  void set(double z, Offset p) {
    zoom = z;
    pan = p;
    notifyListeners();
  }

  void reset() => set(1.0, Offset.zero);
}

/// Scales/translates the canvas and handles two-finger pinch zoom.
///
/// A parent [Transform] inverse-transforms pointer positions for
/// descendants, so the inner Listener in PaintingCanvas keeps receiving
/// canvas coordinates unchanged. Pointer events reach every Listener on
/// the hit path: this outer Listener observes all touch pointers for the
/// pinch without stealing them from the drawing code.
class CanvasViewport extends StatefulWidget {
  const CanvasViewport({
    super.key,
    required this.viewport,
    required this.controller,
    required this.child,
  });

  final CanvasViewportController viewport;
  final CanvasController controller;
  final Widget child;

  @override
  State<CanvasViewport> createState() => _CanvasViewportState();
}

class _CanvasViewportState extends State<CanvasViewport> {
  final Map<int, Offset> _touches = {};
  bool _gestureActive = false;
  double _d0 = 1;
  Offset _f0 = Offset.zero;
  double _z0 = 1;
  Offset _t0 = Offset.zero;

  // Layout-derived values, updated every build.
  Size _viewportSize = Size.zero;
  double _fitScale = 1;
  Offset _fitOffset = Offset.zero;

  Size get _canvasSize => Size(widget.controller.canvasWidth.toDouble(),
      widget.controller.canvasHeight.toDouble());

  Offset get _translation => clampTranslation(
      _fitOffset + widget.viewport.pan,
      _viewportSize,
      _canvasSize,
      _fitScale * widget.viewport.zoom);

  void _pointerDown(PointerDownEvent e) {
    if (e.kind != PointerDeviceKind.touch) return;
    _touches[e.pointer] = e.localPosition;
    if (_touches.length == 2 &&
        !_gestureActive &&
        !widget.controller.stylusDown) {
      widget.controller.beginViewGesture();
      _gestureActive = true;
      _rebaseline();
    }
  }

  void _rebaseline() {
    final pts = _touches.values.toList();
    _d0 = max((pts[0] - pts[1]).distance, 1);
    _f0 = (pts[0] + pts[1]) / 2;
    _z0 = widget.viewport.zoom;
    _t0 = _translation;
  }

  void _pointerMove(PointerMoveEvent e) {
    if (!_touches.containsKey(e.pointer)) return;
    _touches[e.pointer] = e.localPosition;
    if (!_gestureActive || _touches.length < 2) return;

    final pts = _touches.values.take(2).toList();
    final d = max((pts[0] - pts[1]).distance, 1);
    final f = (pts[0] + pts[1]) / 2;
    final z = (_z0 * d / _d0).clamp(1.0, kMaxZoom);
    final sStart = _fitScale * _z0;
    final sNew = _fitScale * z;
    // Keep the canvas point that was under the focal point under it still.
    var t = f - (_f0 - _t0) * (sNew / sStart);
    t = clampTranslation(t, _viewportSize, _canvasSize, sNew);
    widget.viewport.set(z, t - _fitOffset);
  }

  void _pointerUp(PointerEvent e) {
    if (_touches.remove(e.pointer) == null) return;
    if (_gestureActive) {
      if (_touches.length >= 2) {
        // A third finger left — re-anchor to the remaining two.
        _rebaseline();
      } else if (_touches.isEmpty) {
        // Only end at zero fingers, or the leftover finger would draw.
        _gestureActive = false;
        widget.controller.endViewGesture();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final canvas = _canvasSize;
        _fitScale = min(_viewportSize.width / canvas.width,
            _viewportSize.height / canvas.height);
        _fitOffset = Offset(
          (_viewportSize.width - canvas.width * _fitScale) / 2,
          (_viewportSize.height - canvas.height * _fitScale) / 2,
        );
        return ClipRect(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _pointerDown,
            onPointerMove: _pointerMove,
            onPointerUp: _pointerUp,
            onPointerCancel: _pointerUp,
            child: ListenableBuilder(
              listenable: widget.viewport,
              builder: (context, child) {
                final t = _translation;
                final s = _fitScale * widget.viewport.zoom;
                return SizedBox.expand(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translateByDouble(t.dx, t.dy, 0, 1)
                        ..scaleByDouble(s, s, 1, 1),
                      child: SizedBox(
                        width: canvas.width,
                        height: canvas.height,
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
