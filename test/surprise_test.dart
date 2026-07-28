import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/surprise.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/util/color_utils.dart';

/// The dice exists so a child who cannot decide can still start. That only
/// works if every roll is immediately usable — a tool that needs a second
/// choice first, or a colour that cannot be seen on white paper, would make
/// the button look broken instead of generous.
void main() {
  test('every roll can draw straight away', () {
    final rng = Random(42);
    for (var i = 0; i < 200; i++) {
      final dealt = dealSurprise(rng);
      expect(kSurprisePens, contains(dealt.tool));
      // None of these need a sheet opened before a line appears.
      expect(dealt.tool, isNot(ToolKind.stamp));
      expect(dealt.tool, isNot(ToolKind.text));
      expect(dealt.tool, isNot(ToolKind.shape));
      expect(dealt.tool, isNot(ToolKind.eyedropper));
      expect(dealt.tool, isNot(ToolKind.tape));
    }
  });

  test('never a colour that vanishes on the paper', () {
    final rng = Random(7);
    for (var i = 0; i < 200; i++) {
      final dealt = dealSurprise(rng);
      expect(kPaletteColors, contains(dealt.color));
      expect(dealt.color.computeLuminance(), lessThan(0.8),
          reason: 'white on white reads as a pen that does not work');
    }
  });

  test('it really does vary', () {
    // A dice that keeps landing on the brush is not a dice. This is also
    // what would catch an off-by-one that pinned the range to one value.
    final rng = Random(3);
    final tools = <ToolKind>{};
    final colours = <int>{};
    for (var i = 0; i < 60; i++) {
      final dealt = dealSurprise(rng);
      tools.add(dealt.tool);
      colours.add(dealt.color.toARGB32());
    }
    expect(tools.length, greaterThan(4));
    expect(colours.length, greaterThan(4));
  });
}
