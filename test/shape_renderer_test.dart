import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/shape_renderer.dart';
import 'package:pixiepaint/models/tool.dart';

void main() {
  const center = Offset(500, 500);
  const radius = 100.0;

  group('shapePath', () {
    test('every shape stays inside its enclosing circle (small margin)', () {
      final enclosing =
          Rect.fromCircle(center: center, radius: radius * 1.05);
      for (final kind in ShapeKind.values) {
        final bounds =
            ShapeRenderer.shapePath(kind, center, radius).getBounds();
        expect(enclosing.contains(bounds.topLeft), isTrue,
            reason: '$kind top-left outside');
        expect(enclosing.contains(bounds.bottomRight), isTrue,
            reason: '$kind bottom-right outside');
      }
    });

    test('heart and star are horizontally symmetric around the center', () {
      for (final kind in [ShapeKind.heart, ShapeKind.star]) {
        final bounds =
            ShapeRenderer.shapePath(kind, center, radius).getBounds();
        expect(bounds.center.dx, closeTo(center.dx, 0.5),
            reason: '$kind not centered');
      }
    });

    test('star has visible size and 10 corners worth of perimeter', () {
      final path = ShapeRenderer.shapePath(ShapeKind.star, center, radius);
      final bounds = path.getBounds();
      expect(bounds.width, greaterThan(radius));
      expect(bounds.height, greaterThan(radius));
      // A 5-point star's contour is longer than its enclosing circle's
      // diameter but shorter than the full circumference.
      final metric = path.computeMetrics().single;
      expect(metric.length, greaterThan(2 * radius));
    });

    test('circle bounds match the radius exactly', () {
      final bounds =
          ShapeRenderer.shapePath(ShapeKind.circle, center, radius).getBounds();
      expect(bounds.width, closeTo(2 * radius, 0.001));
      expect(bounds.height, closeTo(2 * radius, 0.001));
    });
  });

  group('stampSizeFor', () {
    test('medium preset maps to the classic medium stamp', () {
      expect(stampSizeFor(28), closeTo(220, 0.001));
    });

    test('scales linearly within the clamp range', () {
      expect(stampSizeFor(14), closeTo(110, 0.001));
      expect(stampSizeFor(56), closeTo(440.0.clamp(90.0, 420.0), 0.001));
    });

    test('clamps at both ends', () {
      expect(stampSizeFor(kMinBrushSize), greaterThanOrEqualTo(90));
      expect(stampSizeFor(kMaxBrushSize), lessThanOrEqualTo(420));
    });
  });
}
