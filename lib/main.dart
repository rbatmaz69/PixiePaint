import 'package:flutter/material.dart';

import 'app.dart';
import 'util/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.instance.load();
  runApp(const PixiePaintApp());
}
