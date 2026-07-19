import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/flood_fill.dart';
import 'package:pixiepaint/photo/edge_detect.dart';

/// Builds an opaque RGBA image from a per-pixel gray value.
Uint8List _grayImage(int w, int h, int Function(int x, int y) grayAt) {
  final rgba = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final g = grayAt(x, y);
      final o = (y * w + x) * 4;
      rgba[o] = g;
      rgba[o + 1] = g;
      rgba[o + 2] = g;
      rgba[o + 3] = 255;
    }
  }
  return rgba;
}

int _count(Uint8List mask) => mask.where((v) => v != 0).length;

void main() {
  test('flat image produces an empty mask', () {
    final rgba = _grayImage(64, 64, (x, y) => 180);
    final mask =
        detectEdges(rgba: rgba, width: 64, height: 64, threshold: 64);
    expect(_count(mask), 0);
  });

  test('contrast edge is detected near the boundary only', () {
    const w = 64, h = 32, boundary = 32;
    final rgba = _grayImage(w, h, (x, y) => x < boundary ? 0 : 255);
    final mask = detectEdges(rgba: rgba, width: w, height: h, threshold: 64);
    expect(_count(mask), greaterThan(0));
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final onLine = mask[y * w + x] != 0;
        if (x < boundary - 8 || x > boundary + 8) {
          expect(onLine, isFalse,
              reason: 'unexpected edge pixel far from boundary at ($x,$y)');
        }
      }
    }
  });

  test('higher threshold keeps fewer edge pixels', () {
    // Strong edge (0/255) plus a weak edge (115/140): the weak one should
    // survive the fine threshold but not the bold one.
    const w = 96, h = 32;
    final rgba = _grayImage(w, h, (x, y) {
      if (x < 24) return 0;
      if (x < 48) return 255;
      if (x < 72) return 115;
      return 140;
    });
    final counts = [
      for (final detail in LineArtDetail.values)
        _count(detectEdges(
            rgba: rgba,
            width: w,
            height: h,
            threshold: thresholdFor(detail)))
    ];
    // LineArtDetail order: bold, medium, fine — thresholds descending.
    expect(counts[0], greaterThan(0));
    expect(counts[1], greaterThanOrEqualTo(counts[0]));
    expect(counts[2], greaterThan(counts[0]));
  });

  test('dilation grows the mask', () {
    const w = 64, h = 32;
    final rgba = _grayImage(w, h, (x, y) => x < 32 ? 0 : 255);
    final thin = detectEdges(
        rgba: rgba, width: w, height: h, threshold: 64, dilatePasses: 0);
    final fat = detectEdges(
        rgba: rgba, width: w, height: h, threshold: 64, dilatePasses: 2);
    expect(_count(fat), greaterThan(_count(thin)));
  });

  test('maskToRgba writes the mask into the alpha channel', () {
    final mask = Uint8List.fromList([0, 255, 0, 255]);
    final rgba = maskToRgba(mask, 2, 2);
    for (var i = 0; i < mask.length; i++) {
      expect(rgba[i * 4], 0);
      expect(rgba[i * 4 + 1], 0);
      expect(rgba[i * 4 + 2], 0);
      expect(rgba[i * 4 + 3], mask[i]);
    }
  });

  test('detected outline of a filled square contains a flood fill', () {
    const w = 96, h = 96;
    // Black square on white — detection yields a closed ring around it.
    final rgba = _grayImage(w, h,
        (x, y) => (x >= 24 && x < 72 && y >= 24 && y < 72) ? 0 : 255);
    final barrier =
        detectEdges(rgba: rgba, width: w, height: h, threshold: 64);

    final layer = Uint8List(w * h * 4);
    final result = floodFill(
      rgba: layer,
      barrierAlpha: barrier,
      width: w,
      height: h,
      seedX: 48,
      seedY: 48,
      fillR: 255,
      fillG: 0,
      fillB: 0,
    );
    expect(result, isNotNull);
    // Center is filled…
    expect(result![(48 * w + 48) * 4 + 3], 255);
    // …but the fill never escaped the detected outline.
    expect(result[(5 * w + 5) * 4 + 3], 0);
    expect(result[(90 * w + 90) * 4 + 3], 0);
  });
}
