import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    // The one place in the app that listens to the settings from above.
    // Until the evening mode there was nothing here worth rebuilding for;
    // now the whole tree's theme hangs off one of them.
    return ListenableBuilder(
      listenable: Settings.instance,
      builder: (context, _) => _app(context),
    );
  }

  Widget _app(BuildContext context) {
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
      darkTheme: buildPixieTheme(brightness: Brightness.dark),
      themeMode: Settings.instance.themeMode,
      navigatorObservers: [pixieRouteObserver],
      // A parent's phone set to 200% system text would push the painting
      // toolbars off their fixed heights. Honouring the setting up to a
      // point beats ignoring it (labels do grow) and beats a broken canvas.
      //
      // Raised from 1.3 to 1.6 in v8.3, after the four screens that carry
      // text were taught to give way — `test/widget/text_scale_test.dart`
      // holds that at 360 × 640, the smallest phone this ships to.
      builder: (context, child) {
        // Inside the MaterialApp, so it can see the resolved theme: in the
        // evening the backdrop is dark and the system icons have to be
        // light, or they disappear into it.
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.6,
            child: child!,
          ),
        );
      },
      // The welcome runs once, before the home screen is ever seen.
      home: Settings.instance.welcomeSeen
          ? const HomeScreen()
          : const WelcomeScreen(),
    );
  }
}
