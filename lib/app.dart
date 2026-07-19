import 'package:flutter/material.dart';

import 'gallery/home_screen.dart';
import 'l10n/l10n.dart';

class PixiePaintApp extends StatelessWidget {
  const PixiePaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // German first — it is the fallback for unsupported system languages.
      supportedLocales: const [Locale('de'), Locale('en')],
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
