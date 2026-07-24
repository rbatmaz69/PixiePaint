import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/ui/app_theme.dart';
import 'package:pixiepaint/ui/blob_background.dart';
import 'package:pixiepaint/ui/motion.dart';

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
