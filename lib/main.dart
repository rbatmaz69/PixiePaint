import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'util/settings.dart';
import 'util/sfx.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await Settings.instance.load();
  await Sfx.instance.init();
  runApp(const PixiePaintApp());
}
