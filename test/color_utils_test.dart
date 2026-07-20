import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/color_utils.dart';

void main() {
  group('kidColorGrid', () {
    test('has one row per lightness plus the neutrals row', () {
      final grid = kidColorGrid();
      expect(grid.length, kGridLightness.length + 1);
      for (final row in grid) {
        expect(row.length, kGridHues.length);
      }
    });

    test('all colors are unique and opaque', () {
      final all = kidColorGrid().expand((r) => r).toList();
      expect(all.toSet().length, all.length);
      for (final c in all) {
        expect(c.a, 1.0);
      }
    });

    test('rows get darker top to bottom', () {
      final grid = kidColorGrid();
      for (var i = 1; i < kGridLightness.length; i++) {
        expect(grid[i][0].computeLuminance(),
            lessThan(grid[i - 1][0].computeLuminance()));
      }
    });
  });

  group('needsBorder', () {
    test('white needs a border, black does not', () {
      expect(needsBorder(const Color(0xFFFFFFFF)), isTrue);
      expect(needsBorder(const Color(0xFF000000)), isFalse);
      expect(needsBorder(const Color(0xFFE53935)), isFalse);
    });
  });

  group('pushRecentArgb', () {
    test('prepends and dedups', () {
      var r = pushRecentArgb([], 1);
      r = pushRecentArgb(r, 2);
      r = pushRecentArgb(r, 1);
      expect(r, [1, 2]);
    });

    test('caps at max', () {
      var r = <int>[];
      for (var i = 0; i < 12; i++) {
        r = pushRecentArgb(r, i, max: 8);
      }
      expect(r.length, 8);
      expect(r.first, 11);
      expect(r.last, 4);
    });
  });

  group('colorAtRgba', () {
    test('samples the right pixel and clamps out-of-range coords', () {
      // 2x2 image: red, green / blue, white.
      final buf = Uint8List.fromList([
        255, 0, 0, 255, //
        0, 255, 0, 255, //
        0, 0, 255, 255, //
        255, 255, 255, 255, //
      ]);
      expect(colorAtRgba(buf, 2, 2, 0, 0), const Color(0xFFFF0000));
      expect(colorAtRgba(buf, 2, 2, 1, 0), const Color(0xFF00FF00));
      expect(colorAtRgba(buf, 2, 2, 0, 1), const Color(0xFF0000FF));
      expect(colorAtRgba(buf, 2, 2, 1, 1), const Color(0xFFFFFFFF));
      // clamped
      expect(colorAtRgba(buf, 2, 2, -5, 0), const Color(0xFFFF0000));
      expect(colorAtRgba(buf, 2, 2, 9, 9), const Color(0xFFFFFFFF));
    });
  });
}
