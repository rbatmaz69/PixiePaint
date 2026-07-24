import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pixiepaint/l10n/l10n.dart';
import 'package:pixiepaint/ui/app_theme.dart';
import 'package:pixiepaint/util/profiles.dart';
import 'package:pixiepaint/util/progress.dart';
import 'package:pixiepaint/util/settings.dart';

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

/// Flushes the pending settings/progress writes to disk. Same fake-async
/// caveat as [setUpPixieStorage] — a plain await would never return.
Future<void> flushPixieStorage(WidgetTester tester) => tester.runAsync(() async {
      await Settings.instance.flush();
      await Progress.instance.flush();
      await ProfileStore.instance.flush();
    });

void tearDownPixieStorage(Directory root) {
  Settings.instance.resetForTest();
  ProfileStore.instance.resetForTest();
  Progress.instance.resetForTest();
  if (root.existsSync()) root.deleteSync(recursive: true);
}

/// Pumps [child] inside the app's real theme and localizations, so tests
/// see the same text, sizes and colors a kid does.
///
/// [textScale] drives the accessibility checks: the app clamps system text
/// scaling (at 1.6 since v8.3), and these tests are what keeps that promise
/// honest. It is applied *inside* the clamp on purpose — a test that asks
/// for 1.6 gets 1.6, whatever the clamp above happens to be.
Future<void> pumpPixie(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 800),
  double textScale = 1.0,
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: inner!,
        ),
      ),
      home: child,
    ),
  );
  await tester.pump();
}
