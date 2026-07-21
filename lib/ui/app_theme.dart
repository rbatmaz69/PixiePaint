import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pixie_palette.dart';

/// Design tokens: radii, spacing, sticker geometry and the soft colored
/// shadows used app-wide.
abstract final class PixieTokens {
  static const double rSmall = 16;
  static const double rCard = 28;

  static const double gap = 12;
  static const double gapLarge = 20;

  /// Thick white outline that makes a surface read as a sticker.
  static const double stickerBorder = 4.0;

  /// Deterministic sticker tilt in radians for grid/list slot [index]:
  /// cycles through -1.6°..+1.6° so neighboring stickers never align.
  static double stickerTilt(int index) =>
      (((index * 7) % 5) - 2) * 0.8 * math.pi / 180;

  /// Soft, colored shadow — softer and friendlier than plain black.
  static List<BoxShadow> softShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

/// Gradients derived from [PixiePalette]: one per feature, plus warm paper
/// washes for the screen backgrounds.
abstract final class PixieGradients {
  static const LinearGradient coloring = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PixiePalette.sunshineLight, PixiePalette.sunshine],
  );
  static const LinearGradient freeDraw = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PixiePalette.skyLight, PixiePalette.sky],
  );
  static const LinearGradient photo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PixiePalette.tangerineLight, Color(0xFFFFB7CF)],
  );
  static const LinearGradient gallery = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PixiePalette.mintLight, PixiePalette.mint],
  );
  static const LinearGradient trace = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PixiePalette.bubblegumLight, PixiePalette.bubblegum],
  );
  static const LinearGradient scenes = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PixiePalette.grapeLight, Color(0xFFC5A8F2)],
  );

  // Screen backgrounds — warm paper fading into a whisper of the feature
  // tint.
  static const LinearGradient homeBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, Color(0xFFFFF0E4)],
  );
  static const LinearGradient canvasBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, Color(0xFFF0EBFA)],
  );
  static const LinearGradient pickerBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, Color(0xFFFFF3D9)],
  );
  static const LinearGradient galleryBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, Color(0xFFE9F7EE)],
  );
  static const LinearGradient photoBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, Color(0xFFFFEBE0)],
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

  // Real type scale (not stock M3 sizes): bigger, friendlier headlines,
  // warm ink instead of near-black. Only the text theme carries ink — the
  // color scheme keeps its M3 derivations intact.
  TextStyle style(TextStyle? t, FontWeight w,
          {double? size, double? spacing, double? height}) =>
      (t ?? const TextStyle()).copyWith(
        fontFamily: 'Fredoka',
        fontWeight: w,
        fontSize: size,
        letterSpacing: spacing,
        height: height,
        color: PixiePalette.ink,
      );

  final text = base.textTheme;
  final textTheme = text.copyWith(
    displayLarge: style(text.displayLarge, FontWeight.w700),
    displayMedium: style(text.displayMedium, FontWeight.w700),
    displaySmall: style(text.displaySmall, FontWeight.w700, size: 40),
    headlineLarge: style(text.headlineLarge, FontWeight.w700),
    headlineMedium: style(text.headlineMedium, FontWeight.w700, size: 30),
    headlineSmall: style(text.headlineSmall, FontWeight.w700, size: 26),
    titleLarge: style(text.titleLarge, FontWeight.w600, size: 22),
    titleMedium: style(text.titleMedium, FontWeight.w600, size: 18),
    titleSmall: style(text.titleSmall, FontWeight.w600, size: 16),
    bodyLarge: style(text.bodyLarge, FontWeight.w500, size: 17, height: 1.3),
    bodyMedium: style(text.bodyMedium, FontWeight.w500, size: 15),
    bodySmall: style(text.bodySmall, FontWeight.w500),
    labelLarge:
        style(text.labelLarge, FontWeight.w600, size: 16, spacing: 0.2),
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
    // Dialogs and sheets are stickers themselves: paper fill + thick white
    // outline against the dark barrier.
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PixieTokens.rCard + 4),
        side: const BorderSide(
            color: Colors.white, width: PixieTokens.stickerBorder + 1),
      ),
      backgroundColor: const Color(0xFFFFFDF8),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFFFFFDF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      showDragHandle: true,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? PixiePalette.mint
            : scheme.surfaceContainerHighest,
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 12,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
      activeTrackColor: scheme.primary,
      inactiveTrackColor: PixiePalette.grapeLight,
    ),
    tabBarTheme: TabBarThemeData(
      dividerHeight: 0,
      labelStyle: textTheme.titleMedium,
      unselectedLabelStyle:
          textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
    ),
  );
}
