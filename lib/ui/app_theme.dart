import 'package:flutter/material.dart';

/// Design tokens: radii, spacing and the soft colored shadows used app-wide.
abstract final class PixieTokens {
  static const double rSmall = 16;
  static const double rCard = 28;
  static const double rBlob = 40;

  static const double gap = 12;
  static const double gapLarge = 20;

  /// Soft, colored shadow — softer and friendlier than plain black.
  static List<BoxShadow> softShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

/// Pastel gradients: one per feature, plus screen backgrounds. These replace
/// the previous flat per-screen hex colors.
abstract final class PixieGradients {
  static const LinearGradient coloring = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF3B0), Color(0xFFFFCF71)],
  );
  static const LinearGradient freeDraw = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB5E9FF), Color(0xFF7FDBDA)],
  );
  static const LinearGradient photo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD9C7), Color(0xFFFFB3C8)],
  );
  static const LinearGradient gallery = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC9F5CF), Color(0xFF9BE3B6)],
  );

  // Screen backgrounds — gentle vertical washes.
  static const LinearGradient homeBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF6EDFF), Color(0xFFFFEFF6)],
  );
  static const LinearGradient canvasBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEDE7F6), Color(0xFFE4F0FB)],
  );
  static const LinearGradient pickerBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8E1), Color(0xFFFFEFEF)],
  );
  static const LinearGradient galleryBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F5E9), Color(0xFFE0F5F9)],
  );
  static const LinearGradient photoBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF6EDFF), Color(0xFFFFEBE0)],
  );
}

/// Scale-and-fade page transition with a hint of overshoot — playful but
/// quick, and Hero-compatible.
class PixiePageTransitionsBuilder extends PageTransitionsBuilder {
  const PixiePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
        ),
        child: child,
      ),
    );
  }
}

ThemeData buildPixieTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF7C4DFF));
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  TextStyle style(TextStyle? t, FontWeight w) =>
      (t ?? const TextStyle()).copyWith(fontFamily: 'Fredoka', fontWeight: w);

  final text = base.textTheme;
  final textTheme = text.copyWith(
    displayLarge: style(text.displayLarge, FontWeight.w700),
    displayMedium: style(text.displayMedium, FontWeight.w700),
    displaySmall: style(text.displaySmall, FontWeight.w700),
    headlineLarge: style(text.headlineLarge, FontWeight.w700),
    headlineMedium: style(text.headlineMedium, FontWeight.w700),
    headlineSmall: style(text.headlineSmall, FontWeight.w700),
    titleLarge: style(text.titleLarge, FontWeight.w600),
    titleMedium: style(text.titleMedium, FontWeight.w600),
    titleSmall: style(text.titleSmall, FontWeight.w600),
    bodyLarge: style(text.bodyLarge, FontWeight.w500),
    bodyMedium: style(text.bodyMedium, FontWeight.w500),
    bodySmall: style(text.bodySmall, FontWeight.w500),
    labelLarge: style(text.labelLarge, FontWeight.w600),
    labelMedium: style(text.labelMedium, FontWeight.w500),
    labelSmall: style(text.labelSmall, FontWeight.w500),
  );

  return base.copyWith(
    textTheme: textTheme,
    visualDensity: VisualDensity.comfortable,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PixiePageTransitionsBuilder(),
        TargetPlatform.iOS: PixiePageTransitionsBuilder(),
        TargetPlatform.macOS: PixiePageTransitionsBuilder(),
      },
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(
            fontFamily: 'Fredoka', fontSize: 17, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PixieTokens.rSmall)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(
            fontFamily: 'Fredoka', fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PixieTokens.rCard + 4)),
      backgroundColor: Colors.white,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      showDragHandle: true,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(scheme.onPrimary),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerHeight: 0,
      labelStyle: textTheme.titleMedium,
      unselectedLabelStyle:
          textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
    ),
  );
}
