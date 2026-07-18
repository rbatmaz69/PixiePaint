import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_viewport.dart';

void main() {
  const viewport = Size(800, 600);
  const canvas = Size(2048, 1536);

  group('clampTranslation', () {
    test('centers the canvas when it fits (zoom 1 contain-fit)', () {
      // fitScale for 2048x1536 into 800x600 = 0.390625 → exactly fills.
      const scale = 800 / 2048;
      final t = _CanvasViewportStateProxy.clamp(
          const Offset(500, -300), viewport, canvas, scale);
      expect(t.dx, closeTo(0, 0.001));
      expect(t.dy, closeTo(0, 0.001));
    });

    test('centers a smaller-than-viewport canvas', () {
      const scale = 0.2; // 409.6 x 307.2
      final t = _CanvasViewportStateProxy.clamp(
          Offset.zero, viewport, canvas, scale);
      expect(t.dx, closeTo((800 - 2048 * scale) / 2, 0.001));
      expect(t.dy, closeTo((600 - 1536 * scale) / 2, 0.001));
    });

    test('clamps an oversized canvas so no gap appears', () {
      const scale = 1.0; // canvas 2048x1536 >> viewport
      // Too far right/down (positive translation would leave a gap).
      var t = _CanvasViewportStateProxy.clamp(
          const Offset(50, 80), viewport, canvas, scale);
      expect(t, Offset.zero);
      // Too far left/up.
      t = _CanvasViewportStateProxy.clamp(
          const Offset(-99999, -99999), viewport, canvas, scale);
      expect(t.dx, 800 - 2048.0);
      expect(t.dy, 600 - 1536.0);
      // A legal in-range translation is untouched.
      t = _CanvasViewportStateProxy.clamp(
          const Offset(-100, -200), viewport, canvas, scale);
      expect(t, const Offset(-100, -200));
    });
  });

  group('focal zoom math', () {
    test('canvas point under the focal point stays fixed while zooming', () {
      const fitScale = 800 / 2048; // 0.390625
      const z0 = 1.0;
      const t0 = Offset.zero; // contain-fit at zoom 1 for this geometry
      const focal = Offset(400, 300);

      // Canvas point under the focal point before zooming.
      final canvasPoint = (focal - t0) / (fitScale * z0);

      for (final z in [1.5, 2.0, 4.0]) {
        final sStart = fitScale * z0;
        final sNew = fitScale * z;
        final t = focal - (focal - t0) * (sNew / sStart);
        // Where does that canvas point land now?
        final mapped = t + canvasPoint * sNew;
        expect(mapped.dx, closeTo(focal.dx, 0.001));
        expect(mapped.dy, closeTo(focal.dy, 0.001));
      }
    });

    test('zoom clamps to [1, kMaxZoom]', () {
      expect((0.4).clamp(1.0, kMaxZoom), 1.0);
      expect((99.0).clamp(1.0, kMaxZoom), kMaxZoom);
      expect(kMaxZoom, 4.0);
    });
  });

  group('CanvasViewportController', () {
    test('reset returns to zoom 1 centered', () {
      final c = CanvasViewportController();
      c.set(3, const Offset(-40, -70));
      expect(c.isZoomed, true);
      c.reset();
      expect(c.zoom, 1.0);
      expect(c.pan, Offset.zero);
      expect(c.isZoomed, false);
    });
  });
}

class _CanvasViewportStateProxy {
  static Offset clamp(Offset t, Size viewport, Size canvas, double scale) =>
      clampTranslation(t, viewport, canvas, scale);
}
