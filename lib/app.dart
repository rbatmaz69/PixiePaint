import 'package:flutter/material.dart';

import 'gallery/home_screen.dart';
import 'gallery/welcome_screen.dart';
import 'l10n/l10n.dart';
import 'ui/app_theme.dart';
import 'ui/blob_background.dart';
import 'util/settings.dart';

class PixiePaintApp extends StatelessWidget {
  const PixiePaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // German first — it is the fallback for unsupported system languages.
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('it'),
        Locale('nl'),
        Locale('pl'),
        Locale('pt'),
        Locale('tr'),
      ],
      debugShowCheckedModeBanner: false,
      theme: buildPixieTheme(),
      navigatorObservers: [pixieRouteObserver],
      // A parent's phone set to 200% system text would push the painting
      // toolbars off their fixed heights. Honouring the setting up to a
      // point beats ignoring it (labels do grow) and beats a broken canvas.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: child!,
      ),
      // The welcome runs once, before the home screen is ever seen.
      home: Settings.instance.welcomeSeen
          ? const HomeScreen()
          : const WelcomeScreen(),
    );
  }
}
