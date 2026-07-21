import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/symmetry.dart';

void main() {
  const center = Offset(1024, 768);

  group('symmetryCopies', () {
    test('off yields exactly the identity', () {
      final copies = symmetryCopies(1);
      expect(copies, hasLength(1));
      expect(copies.single.angle, 0);
      expect(copies.single.mirror, isFalse);
    });

    test('butterfly is identity + mirror, no rotation', () {
      final copies = symmetryCopies(2);
      expect(copies, hasLength(2));
      expect(copies[0].mirror, isFalse);
      expect(copies[1].mirror, isTrue);
      expect(copies.every((c) => c.angle == 0), isTrue);
    });

    test('flower and snowflake are pure rotations', () {
      for (final folds in [4, 6]) {
        final copies = symmetryCopies(folds);
        expect(copies, hasLength(folds));
        expect(copies.every((c) => !c.mirror), isTrue);
        for (var k = 0; k < folds; k++) {
          expect(copies[k].angle, closeTo(2 * pi * k / folds, 1e-9));
        }
      }
    });

    test('unknown fold counts fall back to identity', () {
      expect(symmetryCopies(0), hasLength(1));
      expect(symmetryCopies(-3), hasLength(1));
    });
  });

  group('symmetryPoint', () {
    test('identity copy leaves the point untouched', () {
      const p = Offset(100, 200);
      expect(symmetryPoint(p, center, const SymmetryCopy(0, false)), p);
    });

    test('mirror reflects across the vertical center axis', () {
      const p = Offset(1024 - 300, 500);
      final q = symmetryPoint(p, center, const SymmetryCopy(0, true));
      expect(q.dx, closeTo(1024 + 300, 1e-9));
      expect(q.dy, closeTo(500, 1e-9));
    });

    test('point on the mirror axis is a fixed point', () {
      const p = Offset(1024, 333);
      final q = symmetryPoint(p, center, const SymmetryCopy(0, true));
      expect(q.dx, closeTo(p.dx, 1e-9));
      expect(q.dy, closeTo(p.dy, 1e-9));
    });

    test('rotation preserves the distance to the center', () {
      const p = Offset(1500, 400);
      final dist = (p - center).distance;
      for (final copy in symmetryCopies(6)) {
        final q = symmetryPoint(p, center, copy);
        expect((q - center).distance, closeTo(dist, 1e-6));
      }
    });

    test('quarter turn maps up to right around the center', () {
      final p = center - const Offset(0, 100); // straight up
      final q = symmetryPoint(p, center, SymmetryCopy(pi / 2, false));
      expect(q.dx, closeTo(center.dx + 100, 1e-6));
      expect(q.dy, closeTo(center.dy, 1e-6));
    });

    test('full set of rotated copies is closed under another step', () {
      const p = Offset(1300, 900);
      final copies = symmetryCopies(4);
      final positions =
          copies.map((c) => symmetryPoint(p, center, c)).toList();
      // Rotating any copy by one more step lands on another copy.
      final oneStep = SymmetryCopy(2 * pi / 4, false);
      for (final pos in positions) {
        final rotated = symmetryPoint(pos, center, oneStep);
        expect(
          positions.any((other) => (other - rotated).distance < 1e-6),
          isTrue,
        );
      }
    });
  });
}
