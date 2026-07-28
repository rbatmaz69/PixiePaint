import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/color_utils.dart';

/// Mixing is the one thing in this app a child can check against something
/// outside it: a paint box. Blue and yellow have to give green. Every test
/// here is that kind of check — not "the function returns a colour" but
/// "the colour is the one the paint box gives".
void main() {
  double hueOf(Color c) => HSLColor.fromColor(c).hue;
  double satOf(Color c) => HSLColor.fromColor(c).saturation;
  double lightOf(Color c) => HSLColor.fromColor(c).lightness;

  // The paint row's own red, yellow and blue.
  const red = Color(0xFFE53935);
  const yellow = Color(0xFFFFC107);
  const blue = Color(0xFF1E88E5);
  const white = Color(0xFFFFFFFF);
  const black = Color(0xFF000000);

  test('blue and yellow give green', () {
    // The answer light mixing gets wrong: on the screen wheel these two
    // average to a grey, which is why this is the headline case.
    final mixed = mixPaint(blue, yellow);
    expect(hueOf(mixed), inInclusiveRange(75, 165));
    expect(satOf(mixed), greaterThan(0.25), reason: 'green, not grey');
  });

  test('red and yellow give orange', () {
    expect(hueOf(mixPaint(red, yellow)), inInclusiveRange(15, 45));
  });

  test('red and blue give purple, the short way round', () {
    // The long way round runs through green, which is the wrong answer *and*
    // an obviously wrong one to look at.
    expect(hueOf(mixPaint(red, blue)), inInclusiveRange(265, 340));
  });

  test('a colour mixed with itself comes back', () {
    final mixed = mixPaint(red, red);
    expect(hueOf(mixed), closeTo(hueOf(red), 2));
    expect(lightOf(mixed), closeTo(lightOf(red), 0.02));
  });

  test('white tints instead of turning the hue', () {
    final pink = mixPaint(red, white);
    expect(hueOf(pink), closeTo(hueOf(red), 2), reason: 'still a red');
    expect(lightOf(pink), greaterThan(lightOf(red)));
    expect(satOf(pink), lessThan(satOf(red)));
  });

  test('black shades instead of turning the hue', () {
    final dark = mixPaint(red, black);
    expect(hueOf(dark), closeTo(hueOf(red), 2));
    expect(lightOf(dark), lessThan(lightOf(red)));
  });

  test('black and white give a grey in the middle', () {
    final grey = mixPaint(black, white);
    expect(satOf(grey), lessThan(0.05));
    expect(lightOf(grey), closeTo(0.5, 0.02));
  });

  test('colours far apart dull each other', () {
    // Real paint muddies. Mixing across the wheel has to come out less
    // colourful than mixing two neighbours, or "everything at once" would
    // stay as bright as its parts and mixing would mean nothing.
    final neighbours = satOf(mixPaint(red, yellow));
    final across = satOf(mixPaint(red, const Color(0xFF43A047)));
    expect(across, lessThan(neighbours));
  });

  test('mixing is the same either way round', () {
    expect(mixPaint(red, blue), mixPaint(blue, red));
    expect(mixPaint(yellow, white), mixPaint(white, yellow));
  });

  test('the result is always an opaque colour', () {
    // It goes straight onto the paper and into the recently-used row; a
    // half-transparent entry there would paint differently than it looks.
    for (final pair in [
      (red, blue),
      (white, black),
      (yellow, white),
    ]) {
      expect(mixPaint(pair.$1, pair.$2).a, 1.0);
    }
  });
}
