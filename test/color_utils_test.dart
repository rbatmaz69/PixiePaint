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

  group('grid names', () {
    test('there is a name for every column and every neutral', () {
      expect(kGridHueNames.length, kGridHues.length);
      expect(kGridNeutralNames.length, kGridNeutrals.length);
      for (final i in [...kGridHueNames, ...kGridNeutralNames]) {
        expect(i, inInclusiveRange(0, kPaletteColors.length - 1));
      }
    });

    test('the neutrals are named after themselves where they are one of '
        'the sixteen', () {
      // White, brown, grey and black sit in both lists; a name assigned by
      // hand must not disagree with the color it is stuck to.
      for (var i = 0; i < kGridNeutrals.length; i++) {
        final exact = kPaletteColors.indexOf(kGridNeutrals[i]);
        if (exact >= 0) expect(kGridNeutralNames[i], exact);
      }
    });
  });

  group('nearestPaletteIndex', () {
    test('every palette color is its own nearest neighbour', () {
      for (var i = 0; i < kPaletteColors.length; i++) {
        expect(nearestPaletteIndex(kPaletteColors[i]), i,
            reason: 'palette color $i must answer exactly');
      }
    });

    test('a mixed color lands in the right family', () {
      // Hand-checked: the family, not the shade.
      expect(nearestPaletteIndex(const Color(0xFF7A3B91)), 8); // lila
      expect(nearestPaletteIndex(const Color(0xFF0D47A1)), 7); // blau
      expect(nearestPaletteIndex(const Color(0xFFB2FF59)), 3); // hellgrün
      expect(nearestPaletteIndex(const Color(0xFF5D4037)), 11); // braun
      expect(nearestPaletteIndex(const Color(0xFF455A64)), 13); // grau
    });

    test('a near-white is not called white', () {
      // The failure the whole thing exists to avoid: a pale tone collapsing
      // onto a neutral because lightness outweighed hue.
      expect(nearestPaletteIndex(const Color(0xFFB8D9F9)),
          isNot(15)); // pale blue
      expect(nearestPaletteIndex(const Color(0xFFD3B8F9)),
          isNot(15)); // pale purple
    });

    test('answers for every color in the grid', () {
      for (final c in kidColorGrid().expand((r) => r)) {
        expect(nearestPaletteIndex(c),
            inInclusiveRange(0, kPaletteColors.length - 1));
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
