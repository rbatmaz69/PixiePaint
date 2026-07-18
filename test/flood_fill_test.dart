import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/flood_fill.dart';

Uint8List _blank(int w, int h) => Uint8List(w * h * 4);

void _setPixel(Uint8List rgba, int w, int x, int y, List<int> color) {
  final o = (y * w + x) * 4;
  rgba[o] = color[0];
  rgba[o + 1] = color[1];
  rgba[o + 2] = color[2];
  rgba[o + 3] = color[3];
}

List<int> _getPixel(Uint8List rgba, int w, int x, int y) {
  final o = (y * w + x) * 4;
  return [rgba[o], rgba[o + 1], rgba[o + 2], rgba[o + 3]];
}

void main() {
  group('floodFill', () {
    test('fills whole blank canvas without barrier', () {
      const w = 16, h = 16;
      final result = floodFill(
        rgba: _blank(w, h),
        barrierAlpha: null,
        width: w,
        height: h,
        seedX: 5,
        seedY: 5,
        fillR: 255,
        fillG: 0,
        fillB: 0,
      );
      expect(result, isNotNull);
      expect(_getPixel(result!, w, 0, 0), [255, 0, 0, 255]);
      expect(_getPixel(result, w, 15, 15), [255, 0, 0, 255]);
    });

    test('is contained by a barrier wall', () {
      const w = 16, h = 16;
      // vertical wall at x=8
      final barrier = Uint8List(w * h);
      for (var y = 0; y < h; y++) {
        barrier[y * w + 8] = 255;
      }
      final result = floodFill(
        rgba: _blank(w, h),
        barrierAlpha: barrier,
        width: w,
        height: h,
        seedX: 2,
        seedY: 2,
        fillR: 0,
        fillG: 255,
        fillB: 0,
        dilationPasses: 0,
      );
      expect(result, isNotNull);
      expect(_getPixel(result!, w, 7, 5)[3], 255); // left side filled
      expect(_getPixel(result, w, 9, 5)[3], 0); // right side untouched
      expect(_getPixel(result, w, 8, 5)[3], 0); // wall untouched
    });

    test('seed on a barrier is a no-op', () {
      const w = 8, h = 8;
      final barrier = Uint8List(w * h)..[3 * w + 3] = 255;
      final result = floodFill(
        rgba: _blank(w, h),
        barrierAlpha: barrier,
        width: w,
        height: h,
        seedX: 3,
        seedY: 3,
        fillR: 1,
        fillG: 2,
        fillB: 3,
      );
      expect(result, isNull);
    });

    test('refilling with the same color is a no-op', () {
      const w = 8, h = 8;
      final rgba = _blank(w, h);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          _setPixel(rgba, w, x, y, [10, 20, 30, 255]);
        }
      }
      final result = floodFill(
        rgba: rgba,
        barrierAlpha: null,
        width: w,
        height: h,
        seedX: 1,
        seedY: 1,
        fillR: 10,
        fillG: 20,
        fillB: 30,
      );
      expect(result, isNull);
    });

    test('dilation fills under anti-aliased barrier edges', () {
      const w = 16, h = 16;
      final barrier = Uint8List(w * h);
      for (var y = 0; y < h; y++) {
        barrier[y * w + 7] = 100; // soft AA edge, below the 128 wall cutoff
        barrier[y * w + 8] = 255; // hard wall
      }
      final result = floodFill(
        rgba: _blank(w, h),
        barrierAlpha: barrier,
        width: w,
        height: h,
        seedX: 2,
        seedY: 2,
        fillR: 0,
        fillG: 0,
        fillB: 255,
        dilationPasses: 2,
      );
      expect(result, isNotNull);
      // Both the AA pixel and the wall pixel get overpainted by dilation,
      // so no white fringe can show at the line edge.
      expect(_getPixel(result!, w, 7, 5)[3], 255);
      expect(_getPixel(result, w, 8, 5)[3], 255);
      // But the fill must not cross to the other side of the wall.
      expect(_getPixel(result, w, 10, 5)[3], 0);
    });

    test('tolerance matches slightly-different pixels', () {
      const w = 8, h = 8;
      final rgba = _blank(w, h);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          _setPixel(rgba, w, x, y, [200, 200, 200, 255]);
        }
      }
      _setPixel(rgba, w, 4, 4, [190, 210, 195, 255]); // within tolerance 32
      final result = floodFill(
        rgba: rgba,
        barrierAlpha: null,
        width: w,
        height: h,
        seedX: 0,
        seedY: 0,
        fillR: 50,
        fillG: 60,
        fillB: 70,
      );
      expect(result, isNotNull);
      expect(_getPixel(result!, w, 4, 4), [50, 60, 70, 255]);
    });
  });
}
