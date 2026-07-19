import 'package:flutter/material.dart';

import 'gallery/home_screen.dart';
import 'l10n/l10n.dart';
import 'ui/app_theme.dart';

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
      theme: buildPixieTheme(),
      home: const HomeScreen(),
    );
  }
}
