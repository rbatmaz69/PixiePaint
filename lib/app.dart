import 'package:flutter/material.dart';

import 'gallery/home_screen.dart';

class PixiePaintApp extends StatelessWidget {
  const PixiePaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixiePaint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C4DFF)),
        visualDensity: VisualDensity.comfortable,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 48),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
