import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/ui/entrance.dart';

/// The one entrance animation, shared by every screen since v8.4.
///
/// Four screens used to carry their own copy of it. What matters about the
/// replacement is not how it looks but that it always *finishes* — a widget
/// stuck at opacity 0 is an invisible screen — and that it stays a plain
/// pass-through where no group is above it, so a tile can be pumped on its
/// own in a test.
void main() {
  /// No [MaterialApp] on purpose: its route transition is a
  /// [FadeTransition] too, and the assertions below are about the ones
  /// [Entrance] builds.
  Future<void> pump(WidgetTester tester, Widget child,
      {required bool calm}) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: calm),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: child,
        ),
      ),
    );
  }

  /// The transition of type [T] that a given [Entrance] built, if any.
  Finder inside<T extends Widget>(String label) => find.descendant(
        of: find.widgetWithText(Entrance, label),
        matching: find.byType(T),
      );

  testWidgets('the cascade settles and leaves the content fully visible',
      (tester) async {
    await pump(
      tester,
      const EntranceGroup(
        child: Column(
          children: [
            Entrance(slot: 0, child: Text('erste')),
            Entrance(slot: 20, child: Text('letzte')),
          ],
        ),
      ),
      calm: false,
    );

    // Mid-flight the last slot is still on its way in.
    await tester.pump(const Duration(milliseconds: 50));
    final midway = tester.widget<FadeTransition>(inside<FadeTransition>('letzte'));
    expect(midway.opacity.value, lessThan(1.0));

    // And it always arrives — including the slot clamped at the far end.
    await tester.pumpAndSettle();
    for (final label in ['erste', 'letzte']) {
      final settled =
          tester.widget<FadeTransition>(inside<FadeTransition>(label));
      expect(settled.opacity.value, 1.0, reason: '$label blieb unsichtbar');
    }
  });

  testWidgets('with motion reduced the content fades in without moving',
      (tester) async {
    await pump(
      tester,
      const EntranceGroup(
        child: Entrance(slot: 3, child: Text('ruhig')),
      ),
      calm: true,
    );
    await tester.pumpAndSettle();

    // The fade stays — arriving is the point. The travel does not.
    expect(inside<FadeTransition>('ruhig'), findsOneWidget);
    expect(inside<SlideTransition>('ruhig'), findsNothing);
  });

  testWidgets('an Entrance without a group above it just shows its child',
      (tester) async {
    await pump(tester, const Entrance(slot: 4, child: Text('allein')),
        calm: false);
    await tester.pumpAndSettle();

    expect(find.text('allein'), findsOneWidget);
    expect(inside<FadeTransition>('allein'), findsNothing);
  });
}
