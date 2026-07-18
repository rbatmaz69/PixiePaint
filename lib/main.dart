import 'package:flutter/material.dart';

import 'app.dart';
import 'util/settings.dart';
import 'util/sfx.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.instance.load();
  await Sfx.instance.init();
  runApp(const PixiePaintApp());
}
