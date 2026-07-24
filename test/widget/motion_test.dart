import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/ui/app_theme.dart';
import 'package:pixiepaint/ui/blob_background.dart';
import 'package:pixiepaint/ui/motion.dart';
import 'package:pixiepaint/widgets/confetti_burst.dart';

/// "Reduce motion" (Android: remove animations, iOS: reduce motion).
///
/// This app is largely made of movement — drifting blobs, springy buttons,
/// confetti — and until v8.3 none of it asked. The rule it follows now:
/// the *reward* stays, the *movement* goes.
void main() {
  Future<void> pump(WidgetTester tester, Widget child,
      {required bool calm}) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPixieTheme(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: calm),
          child: child,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the drifting background stops when motion is reduced',
      (tester) async {
    await pump(
      tester,
      BlobBackground(
        gradient: PixieGradients.homeBg,
        builder: (context, _) => const SizedBox.expand(),
      ),
      calm: true,
    );

    // The blobs run on an endless 28-second ticker. If it were still
    // going, this would never settle — that is the whole assertion.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the drifting background keeps moving by default',
      (tester) async {
    await pump(
      tester,
      BlobBackground(
        gradient: PixieGradients.homeBg,
        builder: (context, _) => const SizedBox.expand(),
      ),
      calm: false,
    );

    // The counter-proof for the test above: normally the ticker is running,
    // which is exactly why pumpAndSettle is not used here.
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  // Confetti comes in two strengths since v8.4 — sharing a picture should
  // not feel as big as finishing one. What must not change is that
  // "reduce motion" cancels the paper and nothing else.
  group('confetti', () {
    Future<void> fire(WidgetTester tester,
        {required ConfettiScale scale, required bool calm}) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Center(
            child: GestureDetector(
              onTap: () => showConfetti(context, scale: scale),
              child: const Text('los'),
            ),
          ),
        ),
        calm: calm,
      );
      await tester.tap(find.text('los'));
      await tester.pump();
    }

    testWidgets('a party lasts longer than a nod, and both clear themselves up',
        (tester) async {
      // Between the two run times: the nod is over by now, the party is
      // not. That is the difference, expressed in the one way a test can
      // see it from outside.
      const between = Duration(milliseconds: 1200);

      await fire(tester, scale: ConfettiScale.small, calm: false);
      await tester.pump(between);
      expect(tester.binding.hasScheduledFrame, isFalse,
          reason: 'der kleine Jubel lief nach 1,2 s immer noch');

      await fire(tester, scale: ConfettiScale.party, calm: false);
      await tester.pump(between);
      expect(tester.binding.hasScheduledFrame, isTrue,
          reason: 'die große Party war nach 1,2 s schon vorbei');

      // And it removes its own overlay entry rather than sitting there.
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('with motion reduced no paper falls at all', (tester) async {
      await fire(tester, scale: ConfettiScale.party, calm: true);
      // Nothing was inserted, so there is nothing left to settle either.
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  testWidgets('reducedMotion reads the platform setting', (tester) async {
    late bool calm;
    await pump(
      tester,
      Builder(builder: (context) {
        calm = reducedMotion(context);
        return const SizedBox.shrink();
      }),
      calm: true,
    );
    expect(calm, isTrue);
    expect(motionDuration(tester.element(find.byType(SizedBox)),
        const Duration(seconds: 1)),
        Duration.zero);
  });
}
