import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/stroke.dart';
import 'package:pixiepaint/canvas/stroke_renderer.dart';

List<StrokePoint> _line(int n) => [
      for (var i = 0; i < n; i++)
        StrokePoint(Offset(i * 10.0, i * 5.0), 0.5),
    ];

void main() {
  group('hueAt', () {
    test('is deterministic and starts at seed % 360', () {
      expect(StrokeRenderer.hueAt(0, 42), 42);
      expect(StrokeRenderer.hueAt(0, 402), 42);
      expect(StrokeRenderer.hueAt(0, 42), StrokeRenderer.hueAt(0, 42));
    });

    test('advances with distance and wraps at 360', () {
      final quarter =
          StrokeRenderer.hueAt(StrokeRenderer.kRainbowCycleLength / 4, 0);
      expect(quarter, closeTo(90, 0.001));
      final wrapped =
          StrokeRenderer.hueAt(StrokeRenderer.kRainbowCycleLength * 2, 100);
      expect(wrapped, closeTo(100, 0.001));
      expect(wrapped, inInclusiveRange(0, 360));
    });
  });

  group('glitterDots', () {
    test('is deterministic for the same seed and points', () {
      final pts = _line(20);
      final a = StrokeRenderer.glitterDots(pts, 28, 7);
      final b = StrokeRenderer.glitterDots(pts, 28, 7);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].pos, b[i].pos);
        expect(a[i].radius, b[i].radius);
        expect(a[i].colorIndex, b[i].colorIndex);
        expect(a[i].star, b[i].star);
      }
    });

    test('different seeds give different dots', () {
      final pts = _line(20);
      final a = StrokeRenderer.glitterDots(pts, 28, 1);
      final b = StrokeRenderer.glitterDots(pts, 28, 2);
      expect(
        a.length != b.length ||
            List.generate(a.length, (i) => a[i].pos != b[i].pos)
                .any((d) => d),
        true,
      );
    });

    test('prefix stability: appending points never moves earlier dots', () {
      final short = _line(10);
      final long = _line(25);
      final a = StrokeRenderer.glitterDots(short, 28, 99);
      final b = StrokeRenderer.glitterDots(long, 28, 99);
      expect(b.length, greaterThanOrEqualTo(a.length));
      for (var i = 0; i < a.length; i++) {
        expect(b[i].pos, a[i].pos);
        expect(b[i].radius, a[i].radius);
      }
    });

    test('dot count is capped', () {
      final pts = [
        for (var i = 0; i < 5000; i++)
          StrokePoint(Offset(i * 50.0, 0), 0.5),
      ];
      final dots = StrokeRenderer.glitterDots(pts, 28, 3);
      expect(dots.length, lessThanOrEqualTo(StrokeRenderer.kMaxGlitterDots));
    });
  });
}
