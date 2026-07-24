import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/gallery/slideshow_screen.dart';

/// The dot row under the slideshow (v8.4).
///
/// It says which picture of how many without asking anyone to read a
/// number — but a gallery can hold forty pictures, and forty dots on a
/// phone in landscape is a dotted line, not a count. So the row is a window
/// of seven, and the window is the part that can be wrong.
void main() {
  Future<void> pump(WidgetTester tester,
          {required int count, required int index}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: SlideDots(count: count, index: index)),
          ),
        ),
      );

  /// Dots are the only AnimatedContainers here; the wide one is the active
  /// picture.
  ({int shown, int activeAt}) read(WidgetTester tester) {
    final widths = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => c.constraints?.maxWidth ?? 0)
        .toList();
    return (
      shown: widths.length,
      activeAt: widths.indexWhere((w) => w > 8),
    );
  }

  testWidgets('a short show gets one dot per picture', (tester) async {
    await pump(tester, count: 4, index: 2);
    expect(read(tester), (shown: 4, activeAt: 2));
  });

  testWidgets('a long show shows a window of seven', (tester) async {
    await pump(tester, count: 40, index: 20);
    // Centered: three dots either side of the active one.
    expect(read(tester), (shown: 7, activeAt: 3));
  });

  testWidgets('the window sticks to the ends instead of running off them',
      (tester) async {
    // At the very start the active dot cannot be centered — the window
    // stays put and the dot moves inside it.
    await pump(tester, count: 40, index: 0);
    expect(read(tester), (shown: 7, activeAt: 0));

    await pump(tester, count: 40, index: 39);
    expect(read(tester), (shown: 7, activeAt: 6));
  });

  testWidgets('a single picture still reads as one dot', (tester) async {
    await pump(tester, count: 1, index: 0);
    expect(read(tester), (shown: 1, activeAt: 0));
  });

  testWidgets('a screen reader hears the number the dots stand for',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, count: 17, index: 3);

    expect(find.bySemanticsLabel('4 / 17'), findsOneWidget);

    handle.dispose();
  });
}
