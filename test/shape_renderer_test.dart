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

    test('a mask shape holds the middle and leaves the corners', () {
      // What the sticker cut-out relies on: clipping to a heart or a star
      // keeps the middle of the photo and drops the corners of its box. A
      // path that failed this would produce a sticker with clipped edges or
      // no transparency at all.
      for (final kind in [ShapeKind.heart, ShapeKind.star]) {
        final path = ShapeRenderer.shapePath(kind, center, radius);
        expect(path.contains(center), isTrue, reason: '$kind loses its middle');
        for (final corner in [
          center + const Offset(-radius, -radius),
          center + const Offset(radius, -radius),
          center + const Offset(-radius, radius),
          center + const Offset(radius, radius),
        ]) {
          expect(path.contains(corner), isFalse,
              reason: '$kind reaches into the corner at $corner');
        }
      }
    });

    test('a line is a line, not an area', () {
      final path = ShapeRenderer.shapePath(ShapeKind.line, center, radius);
      expect(path.contains(center + const Offset(0, 40)), isFalse,
          reason: 'an open path must enclose nothing');
      expect(ShapeRenderer.isOpen(ShapeKind.line), isTrue);
      expect(ShapeRenderer.isOpen(ShapeKind.triangle), isFalse);
    });

    test('the line follows the angle it is given', () {
      final flat = ShapeRenderer.shapePath(ShapeKind.line, center, radius)
          .getBounds();
      expect(flat.height, lessThan(1), reason: 'no angle means flat');

      final upright = ShapeRenderer.shapePath(ShapeKind.line, center, radius,
              angle: 1.5707963)
          .getBounds();
      expect(upright.width, lessThan(1));
      expect(upright.height, closeTo(radius * 2, 1));
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
