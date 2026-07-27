import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pixiepaint/l10n/l10n.dart';
import 'package:pixiepaint/ui/app_theme.dart';
import 'package:pixiepaint/util/error_log.dart';
import 'package:pixiepaint/util/profiles.dart';
import 'package:pixiepaint/util/progress.dart';
import 'package:pixiepaint/util/settings.dart';
import 'package:pixiepaint/widgets/parental_gate.dart';

/// Shared setup for the widget tests.
///
/// Everything the app touches at startup is filesystem-backed, so each test
/// gets its own documents directory and its own freshly loaded singletons —
/// the same wiring `main()` does, minus audio.
class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

/// Creates a temp documents dir, points path_provider at it and loads
/// settings, profiles and progress. Returns the directory so a test can
/// inspect what the app wrote.
///
/// Wrapped in [WidgetTester.runAsync] because `testWidgets` runs its body
/// in a fake-async zone where real file I/O never completes — without it
/// the first `await` here hangs the test forever rather than failing.
Future<Directory> setUpPixieStorage(WidgetTester tester) async {
  late Directory root;
  await tester.runAsync(() async {
    root = Directory.systemTemp.createTempSync('pp_widget');
    PathProviderPlatform.instance = _TempPathProvider(root.path);
    Settings.instance.resetForTest();
    ProfileStore.instance.resetForTest();
    Progress.instance.resetForTest();
    await Settings.instance.load();
    await ProfileStore.instance.load();
    await Progress.instance.load(ProfileStore.instance.active.id);
  });
  return root;
}

/// Waits until [done] holds, turning both of the clocks a widget test runs
/// on.
///
/// This is the shape every "did the disk catch up yet?" wait in these tests
/// needs, and getting it wrong is silent. Work started from a tap lives in
/// the fake-async zone and its `await`s only continue when the tester
/// pumps; the file I/O underneath needs real time, which only `runAsync`
/// grants. Poll in `runAsync` alone and the wait blocks the very work it is
/// waiting for — measured on the gallery's delete test,
/// `Directory.delete` was not even *called* until the five second cap had
/// run out, and the assertion after it then raced the deletion instead of
/// following it. Pump alone and the file work never gets a real moment to
/// happen.
///
/// Returns whether [done] held in the end, so a caller can tell a slow
/// success from a timeout.
Future<bool> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
  }
  await tester.pump();
  return done();
}

/// Waits for the pending settings/progress/log writes to reach the disk.
///
/// The flush futures themselves complete on fake-async microtasks — the
/// `register*` mutators queue their writes from inside the zone — so this
/// cannot simply `await` them: that hangs forever the moment the test body
/// is over and nobody pumps any more. Hence the unawaited kick-off plus
/// [pumpUntil].
Future<void> flushPixieStorage(WidgetTester tester) async {
  var flushed = false;
  void markDone([Object? _, StackTrace? _]) => flushed = true;
  unawaited(Future.wait([
    Settings.instance.flush(),
    Progress.instance.flush(),
    ProfileStore.instance.flush(),
    ErrorLog.instance.flush(),
  ]).then(markDone, onError: markDone));
  await pumpUntil(tester, () => flushed);
}

/// Resets the singletons and removes the test's temp directory.
///
/// The flush is not optional, which is why this takes the tester at all.
/// The `register*` mutators write fire-and-forget, so a test can end with a
/// write still in flight; `JsonStore` then creates its `.tmp` file inside
/// the directory this function is halfway through deleting, and the delete
/// fails with `Directory not empty` (errno 66). That was a measured flake
/// in find_again_test and profile_sheet_test, not a hypothetical — and it
/// showed up as an error in whichever test happened to be running next.
Future<void> tearDownPixieStorage(WidgetTester tester, Directory root) async {
  await flushPixieStorage(tester);
  Settings.instance.resetForTest();
  ProfileStore.instance.resetForTest();
  Progress.instance.resetForTest();
  ParentalGate.resetForTest();
  if (root.existsSync()) root.deleteSync(recursive: true);
}

/// Pumps [child] inside the app's real theme and localizations, so tests
/// see the same text, sizes and colors a kid does.
///
/// [textScale] drives the accessibility checks: the app clamps system text
/// scaling (at 1.6 since v8.3), and these tests are what keeps that promise
/// honest. It is applied *inside* the clamp on purpose — a test that asks
/// for 1.6 gets 1.6, whatever the clamp above happens to be.
///
/// [reduceMotion] is the platform's "remove animations" switch, which the
/// app honours everywhere (see `motion_test.dart`).
Future<void> pumpPixie(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 800),
  double textScale = 1.0,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('de'), Locale('en')],
      locale: const Locale('de'),
      theme: buildPixieTheme(),
      builder: (context, inner) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: inner!,
        ),
      ),
      home: child,
    ),
  );
  await tester.pump();
}
