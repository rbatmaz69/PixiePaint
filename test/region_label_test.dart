import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/region_label.dart';

/// Alpha map helper: 255 where [wall] returns true.
Uint8List _walls(int w, int h, bool Function(int x, int y) wall) {
  final alpha = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (wall(x, y)) alpha[y * w + x] = 255;
    }
  }
  return alpha;
}

void main() {
  test('blank canvas is one region', () {
    final regions = labelRegions(Uint8List(16 * 16), 16, 16);
    expect(regions.toSet(), {1});
  });

  test('a vertical wall splits the canvas into two regions', () {
    final alpha = _walls(16, 16, (x, y) => x == 8);
    final regions = labelRegions(alpha, 16, 16);
    expect(regions[0], 1);
    expect(regions[15], 2);
    expect(regions[8], 0); // wall itself
    // Left column pixels all share region 1, right ones region 2.
    for (var y = 0; y < 16; y++) {
      expect(regions[y * 16], 1);
      expect(regions[y * 16 + 15], 2);
    }
  });

  test('a closed box yields inside and outside regions', () {
    final alpha = _walls(
        32, 32, (x, y) => (x == 8 || x == 24 || y == 8 || y == 24) &&
            x >= 8 && x <= 24 && y >= 8 && y <= 24);
    final regions = labelRegions(alpha, 32, 32);
    final outside = regions[0];
    final inside = regions[16 * 32 + 16];
    expect(outside, isNot(0));
    expect(inside, isNot(0));
    expect(inside, isNot(outside));
  });

  test('ids are deterministic across runs', () {
    final alpha = _walls(64, 64, (x, y) => (x + y) % 17 == 0);
    final a = labelRegions(alpha, 64, 64);
    final b = labelRegions(alpha, 64, 64);
    expect(a, b);
  });

  test('region matches what a flood fill would cover: same threshold', () {
    // Anti-aliased edge alpha 100 (< 128) is walkable, 200 is a wall.
    final alpha = Uint8List(4)..[1] = 100..[2] = 200..[3] = 255;
    final regions = labelRegions(alpha, 4, 1);
    expect(regions[0], 1);
    expect(regions[1], 1);
    expect(regions[2], 0);
    expect(regions[3], 0);
  });
}
