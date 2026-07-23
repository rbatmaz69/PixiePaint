import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'util/music.dart';
import 'util/profiles.dart';
import 'util/progress.dart';
import 'util/settings.dart';
import 'util/sfx.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  await Settings.instance.load();
  // Profiles first: their load() migrates the pre-profiles progress.json to
  // the primary profile, which Progress then reads back.
  await ProfileStore.instance.load();
  await Progress.instance.load(ProfileStore.instance.active.id);
  await Sfx.instance.init();
  await Music.instance.init();
  runApp(const PixiePaintApp());
}
