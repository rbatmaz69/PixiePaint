import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'ui/oops_card.dart';
import 'util/error_log.dart';
import 'util/json_store.dart' show onPersistFailure;
import 'util/music.dart';
import 'util/profiles.dart';
import 'util/progress.dart';
import 'util/settings.dart';
import 'util/sfx.dart';

void main() {
  // The zone is the outermost net: it catches what the two handlers set up in
  // _installErrorHandlers do not see, including anything thrown while the
  // startup below is still running. Started rather than awaited on purpose —
  // the zone's body outlives main() by the whole life of the app.
  runZonedGuarded(() {
    unawaited(_startUp());
  }, (error, stack) {
    ErrorLog.instance.record(error, stack, origin: ErrorOrigin.zone);
  });
}

Future<void> _startUp() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();
  // Flutter defaults to 100 MB of decoded images. The gallery already asks
  // for its thumbnails at display size (`cacheWidth`), so it never needs
  // that much — and the painting canvas wants the headroom far more, since
  // its own layers are 12 MB apiece.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 32 * 1024 * 1024;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  // Before the stores: it reads its own file and takes over the entries
  // buffered so far, so a failure in any load() below is already recorded.
  await ErrorLog.instance.init();
  await Settings.instance.load();
  // Profiles first: their load() migrates the pre-profiles progress.json to
  // the primary profile, which Progress then reads back.
  await ProfileStore.instance.load();
  await Progress.instance.load(ProfileStore.instance.active.id);
  await Sfx.instance.init();
  await Music.instance.init();
  runApp(const PixiePaintApp());
}

/// Gives the app the one thing it had no version of: a memory of what went
/// wrong. PixiePaint ships no crash reporter by design — that promise stands,
/// and this is its local counterpart. See [ErrorLog].
void _installErrorHandlers() {
  FlutterError.onError = (details) {
    ErrorLog.instance
        .record(details.exception, details.stack, origin: ErrorOrigin.flutter);
    // Keep the red screens and console output while developing: the log is
    // for devices in a child's hands, not for the machine that builds it.
    FlutterError.presentError(details);
  };

  // Async errors nobody awaited — a plugin's platform channel, for instance.
  // Returning true means "handled": we have written it down, and taking the
  // app down in a child's hands would gain nothing.
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLog.instance.record(error, stack, origin: ErrorOrigin.platform);
    return true;
  };

  // Swallowed write failures (see json_store.dart). Practically the most
  // valuable entries in the log: they mean something did not persist.
  onPersistFailure = (error, stack, path) {
    ErrorLog.instance
        .record(error, stack, origin: ErrorOrigin.save, detail: path);
  };

  // A build that throws leaves a grey box in release and striped bars in
  // debug. The grey box is what a child would meet, so only that one is
  // replaced — in debug the loud version is the useful version.
  //
  // No recording here: `FlutterError.onError` above has already seen this
  // exact exception (a throwing build reports it and *then* asks for the
  // replacement widget). Writing it down twice would double every entry.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const OopsCard();
  }
}
