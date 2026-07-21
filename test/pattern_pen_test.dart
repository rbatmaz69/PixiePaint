import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/stroke.dart';
import 'package:pixiepaint/canvas/stroke_renderer.dart';

List<StrokePoint> _line(double fromX, double toX, {double step = 10}) => [
      for (var x = fromX; x <= toX; x += step)
        StrokePoint(Offset(x, 100), 0.5)
    ];

void main() {
  group('trailMotifs', () {
    test('spacing follows the brush size', () {
      final pts = _line(0, 1000);
      final motifs = StrokeRenderer.trailMotifs(pts, 28, 7);
      // ~1000 / (28 * 2.2) + the starting motif.
      expect(motifs.length,
          closeTo(1000 / (28 * StrokeRenderer.kTrailSpacingFactor) + 1, 1.5));
      for (var i = 1; i < motifs.length; i++) {
        final gap = (motifs[i].pos - motifs[i - 1].pos).distance;
        expect(gap, closeTo(28 * StrokeRenderer.kTrailSpacingFactor, 0.5));
      }
    });

    test('appending points never moves earlier motifs (stable preview)', () {
      final full = _line(0, 800);
      final prefix = full.sublist(0, full.length ~/ 2);
      final motifsPrefix = StrokeRenderer.trailMotifs(prefix, 28, 42);
      final motifsFull = StrokeRenderer.trailMotifs(full, 28, 42);
      expect(motifsFull.length, greaterThan(motifsPrefix.length));
      for (var i = 0; i < motifsPrefix.length; i++) {
        expect(motifsFull[i].pos, motifsPrefix[i].pos);
        expect(motifsFull[i].size, motifsPrefix[i].size);
        expect(motifsFull[i].motif, motifsPrefix[i].motif);
        expect(motifsFull[i].angle, motifsPrefix[i].angle);
      }
    });

    test('motifs cycle heart/star/dot', () {
      final motifs = StrokeRenderer.trailMotifs(_line(0, 500), 28, 1);
      for (var i = 0; i < motifs.length; i++) {
        expect(motifs[i].motif, i % 3);
      }
    });

    test('same seed, same motifs; different seed, different jitter', () {
      final pts = _line(0, 400);
      final a = StrokeRenderer.trailMotifs(pts, 28, 5);
      final b = StrokeRenderer.trailMotifs(pts, 28, 5);
      final c = StrokeRenderer.trailMotifs(pts, 28, 6);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].size, b[i].size);
        expect(a[i].angle, b[i].angle);
      }
      expect(
        [for (final m in a) m.angle],
        isNot([for (final m in c) m.angle]),
      );
    });
  });

  group('dottedCenters', () {
    test('even spacing across segment boundaries', () {
      // Uneven segment lengths must not disturb the rhythm.
      final pts = [
        const StrokePoint(Offset(0, 0), 0.5),
        const StrokePoint(Offset(13, 0), 0.5),
        const StrokePoint(Offset(90, 0), 0.5),
        const StrokePoint(Offset(300, 0), 0.5),
      ];
      final centers = StrokeRenderer.dottedCenters(pts, 50);
      for (var i = 1; i < centers.length; i++) {
        expect((centers[i] - centers[i - 1]).distance, closeTo(50, 0.001));
      }
      expect(centers.first, const Offset(0, 0));
    });

    test('prefix stability like the trail pen', () {
      final full = _line(0, 600);
      final prefix = full.sublist(0, 20);
      final a = StrokeRenderer.dottedCenters(prefix, 40);
      final b = StrokeRenderer.dottedCenters(full, 40);
      for (var i = 0; i < a.length; i++) {
        expect(b[i], a[i]);
      }
    });
  });

  group('offsetPolyline', () {
    test('horizontal line shifts straight up/down', () {
      final pts = _line(0, 100);
      final up = StrokeRenderer.offsetPolyline(pts, -10);
      final down = StrokeRenderer.offsetPolyline(pts, 10);
      for (var i = 0; i < pts.length; i++) {
        expect(up[i].dy, closeTo(100 - 10, 0.001));
        expect(down[i].dy, closeTo(100 + 10, 0.001));
        expect(up[i].dx, pts[i].pos.dx);
      }
    });

    test('rails keep a constant distance of twice the offset', () {
      final pts = [
        for (var i = 0; i < 20; i++)
          StrokePoint(Offset(i * 20.0, 100 + 30 * (i % 2)), 0.5)
      ];
      final left = StrokeRenderer.offsetPolyline(pts, -8);
      final right = StrokeRenderer.offsetPolyline(pts, 8);
      for (var i = 0; i < pts.length; i++) {
        expect((left[i] - right[i]).distance, closeTo(16, 0.001));
      }
    });
  });
}
