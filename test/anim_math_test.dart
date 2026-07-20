import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/anim_math.dart';

void main() {
  group('lockedWiggleAngle', () {
    test('is exactly zero outside the wag window', () {
      // Index 0: window is [0, 0.14).
      for (var t = 0.15; t < 1.0; t += 0.01) {
        expect(lockedWiggleAngle(t, 0), 0,
            reason: 'expected rest at t=$t');
      }
    });

    test('never exceeds the amplitude', () {
      for (var i = 0; i < 5; i++) {
        for (var t = 0.0; t < 1.0; t += 0.003) {
          expect(lockedWiggleAngle(t, i).abs(),
              lessThanOrEqualTo(0.09 + 1e-9));
        }
      }
    });

    test('actually moves inside the window', () {
      var maxAbs = 0.0;
      for (var t = 0.0; t < 0.14; t += 0.002) {
        maxAbs = maxAbs > lockedWiggleAngle(t, 0).abs()
            ? maxAbs
            : lockedWiggleAngle(t, 0).abs();
      }
      expect(maxAbs, greaterThan(0.05));
    });

    test('adjacent tiles are phase shifted', () {
      // At t where tile 0 rests, tile 1's window (phase +0.23) differs.
      final a = List.generate(100, (i) => lockedWiggleAngle(i / 100, 0));
      final b = List.generate(100, (i) => lockedWiggleAngle(i / 100, 1));
      expect(a, isNot(equals(b)));
    });

    test('is periodic in t', () {
      for (var t = 0.0; t < 1.0; t += 0.05) {
        expect(lockedWiggleAngle(t + 1.0, 3),
            closeTo(lockedWiggleAngle(t, 3), 1e-9));
      }
    });
  });
}
