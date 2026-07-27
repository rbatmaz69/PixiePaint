import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'pixie_palette.dart';
import 'pixie_surfaces.dart';

/// Design tokens: radii, spacing, sticker geometry and the soft colored
/// shadows used app-wide.
abstract final class PixieTokens {
  static const double rSmall = 16;

  /// Sticker cards.
  ///
  /// It was 28, and eleven of the twelve places that build a [StickerCard]
  /// passed a number instead — nine of them 24, the rest 22 and 18. The
  /// token was not wrong so much as ignored, so it now says what the app
  /// actually looks like rather than what it was once meant to.
  static const double rCard = 24;

  /// Picker tiles, chips and the paper sheet.
  static const double rTile = 20;

  /// Anything pill-shaped: the tool bars, and the white chips that float
  /// over the paper. One of the four had already drifted to 22.
  static const double rPill = 24;

  /// Dialogs and bottom sheets. They are the same surface seen from two
  /// directions and used to arrive at 32 by two unrelated routes.
  static const double rSheet = 32;

  // Two kinds of radius deliberately stay off this list, so that finding a
  // bare number in the code still means something:
  //
  // * **Hairlines** (2–4): the crayon underline in the header, a progress
  //   bar's cap, the dots of a page indicator. Those are the thickness of
  //   the thing itself, not a corner treatment.
  // * **Inner clips**: an image clipped *inside* a rounded frame has to
  //   lose roughly the padding between the two, or the corners pinch
  //   visibly. It is derived from its frame, not chosen — see the gallery's
  //   polaroid and the storage tile.

  /// The spacing ladder. Not a 4-grid on principle — these are the rungs
  /// the app already stood on, so adopting them moves nothing. The two
  /// smallest sit close together because 6 and 8 do different jobs: 6 packs
  /// a row of small things, 8 separates an emoji from its label.
  static const double gapTiny = 6;
  static const double gapSmall = 8;
  static const double gap = 12;
  static const double gapMedium = 16;
  static const double gapLarge = 20;
  static const double gapXl = 24;
  static const double gapHuge = 32;

  /// Thick white outline that makes a surface read as a sticker.
  static const double stickerBorder = 4.0;

  /// Deterministic sticker tilt in radians for grid/list slot [index]:
  /// cycles through -1.6°..+1.6° so neighboring stickers never align.
  static double stickerTilt(int index) =>
      (((index * 7) % 5) - 2) * 0.8 * math.pi / 180;

  /// The hairline that keeps a pale swatch from disappearing into the white
  /// under it.
  ///
  /// The palette says the app never paints plain black, and then six places
  /// reached for `Colors.black26` anyway — the paint palette, the size
  /// sheet and the size button, all drawing the same outline around the
  /// same too-light colours. It is ink, quietly.
  static Color hairline([double alpha = 0.26]) =>
      PixiePalette.ink.withValues(alpha: alpha);

  /// The dark behind a modal. Three of them, three different darks
  /// (0.72, 0.54, 0.55) — and a scrim is one decision, not three.
  static Color scrim([double alpha = 0.6]) =>
      PixiePalette.ink.withValues(alpha: alpha);

  /// The second line: a caption, a subtitle, the sentence under a heading.
  ///
  /// Eight places wrote `ink.withValues(alpha: 0.7)` and two more reached
  /// for 0.6 to say the same thing. The alpha ladder as a whole is not worth
  /// naming — most of those numbers are one-offs with a reason — but this
  /// one is a role the app plays over and over.
  static Color get quietInk => PixiePalette.ink.withValues(alpha: 0.7);

  /// Border widths, in the three jobs they actually do: the hairline that
  /// outlines a pale swatch, the ordinary edge, and the ring that marks a
  /// selection. [stickerBorder] is the fourth and thickest.
  static const double strokeHair = 1.5;
  static const double strokeEdge = 2.0;
  static const double strokeSelect = 2.5;

  /// The lift under the white bars that float over the paper — the tool
  /// strip, the rail, the button pills inside them.
  ///
  /// Tighter and quieter than [softShadow] on purpose: these sit *close*
  /// above the drawing and must not throw a halo across it. Three places
  /// carried three near-copies of it with different numbers.
  static List<BoxShadow> barShadow() => [
        BoxShadow(
          color: PixiePalette.grape.withValues(alpha: 0.14),
          blurRadius: 11,
          offset: const Offset(0, 3),
        ),
      ];

  /// The white bars themselves: rounded, opaque, lifted by [barShadow].
  ///
  /// The tool strip and the rail are the same object seen upright and on its
  /// side, so they should not be able to drift apart in radius or fill.
  static BoxDecoration barDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rPill),
        boxShadow: barShadow(),
      );

  /// Soft, colored shadow — softer and friendlier than plain black.
  ///
  /// Two layers since v8.4: a tight contact shadow right under the edge,
  /// and the wide soft one that was always here. One alone reads as
  /// floating; together the sticker sits *on* the paper.
  ///
  /// Both radii are fixed on purpose. These shadows get tweened by
  /// [AnimatedContainer] with overshooting curves (see the toolbar), and a
  /// blur radius pulled below zero is an assertion in `dart:ui` — so only
  /// the alpha, which [Color.lerp] clamps, is ever allowed to vary.
  ///
  /// [strength] is what makes that reachable: a control that only *some­times*
  /// casts a shadow must fade it via `strength: 0` rather than by handing
  /// [AnimatedContainer] a `null` to tween against. Tweening a shadow list
  /// against `null` is the same negative-blur crash by another route, and it
  /// used to sit in six widgets at once — every picker built on
  /// `stickerSelectionDecoration`, plus the toolbar's action buttons. With a
  /// zero-alpha shadow always present there is nothing left to get wrong,
  /// and any curve is safe.
  static List<BoxShadow> softShadow(Color color, {double strength = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.18 * strength),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.22 * strength),
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
    colors: [PixiePalette.tangerineLight, PixiePalette.blushLight],
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
    colors: [PixiePalette.grapeLight, PixiePalette.grapeMid],
  );
  /// Trophy gold. Warmer than [coloring] on purpose — the two sit next to
  /// each other on the home screen and must not read as the same card.
  static const LinearGradient rewards = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PixiePalette.sunshine, PixiePalette.tangerine],
  );

  // Screen backgrounds — warm paper fading into a whisper of the feature
  // tint.
  static const LinearGradient homeBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, PixiePalette.paperWarm],
  );
  static const LinearGradient canvasBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, PixiePalette.paperViolet],
  );
  static const LinearGradient pickerBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, PixiePalette.paperSun],
  );
  static const LinearGradient galleryBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, PixiePalette.paperMint],
  );
  static const LinearGradient photoBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [PixiePalette.paper, PixiePalette.paperPeach],
  );
}

/// Scale-and-fade page transition with a hint of overshoot — playful but
/// quick, and Hero-compatible.
///
/// Both directions are handled. Until v8.6 only [animation] was: the
/// arriving screen grew in, and the one it landed on top of just sat there
/// at full size and full brightness behind it. That reads as two unrelated
/// pictures swapping rather than as one screen covering another, and it is
/// the single cheapest thing in the app that makes navigation feel flat.
/// Now the covered screen also steps back a little and dims, so there is a
/// front and a back.
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
    // With "reduce motion" on, screens still arrive — they just stop
    // travelling to get here. Both the growing and the stepping back go.
    if (reducedMotion(context)) {
      return FadeTransition(opacity: animation, child: child);
    }

    // Being covered by the next screen: back off and dim. Quiet on
    // purpose — this is depth, not a second animation competing with the
    // one the eye is meant to follow.
    final away = CurvedAnimation(
      parent: secondaryAnimation,
      curve: PixieCurves.enter,
      reverseCurve: PixieCurves.exit,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.65).animate(away),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.92).animate(away),
        // Arriving.
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: PixieCurves.enter),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: PixieCurves.spring,
                reverseCurve: PixieCurves.exit,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The seed Material 3 derives its whole scheme from.
///
/// The one color in the app that is never painted — only divided into
/// tones — which is why it stays here instead of joining [PixiePalette].
/// It is a shade off [PixiePalette.grape] on purpose: pulling it onto the
/// palette value would move every derived tone (buttons, slider, tabbar)
/// with it.
const Color _seed = Color(0xFF7C4DFF);

ThemeData buildPixieTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
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
        // Ink in both modes, and that is on purpose. Almost every word in
        // this app is written inside something white — a sticker card, a
        // dialog, the tool bar — and those stay white in the evening. The
        // handful of places where text lies directly on the backdrop ask
        // for `context.surfaces.onGround` instead.
        color: PixiePalette.ink,
      );

  // Fredoka runs wide at display sizes — a touch of negative tracking on
  // the big grades keeps a headline reading as one word rather than a row
  // of letters. The body sizes keep their default spacing; they are already
  // comfortable and children read them slowly.
  final text = base.textTheme;
  final textTheme = text.copyWith(
    displayLarge: style(text.displayLarge, FontWeight.w700, spacing: -0.8),
    displayMedium: style(text.displayMedium, FontWeight.w700, spacing: -0.6),
    displaySmall:
        style(text.displaySmall, FontWeight.w700, size: 40, spacing: -0.5),
    headlineLarge: style(text.headlineLarge, FontWeight.w700, spacing: -0.5),
    headlineMedium:
        style(text.headlineMedium, FontWeight.w700, size: 30, spacing: -0.4),
    headlineSmall:
        style(text.headlineSmall, FontWeight.w700, size: 26, spacing: -0.3),
    // Card labels wrap to two lines; without the extra leading they touch.
    titleLarge: style(text.titleLarge, FontWeight.w600, size: 22, height: 1.25),
    titleMedium:
        style(text.titleMedium, FontWeight.w600, size: 18, height: 1.25),
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
    extensions: [dark ? PixieSurfaces.dusk : PixieSurfaces.day],
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
        // From the ladder, not beside it. Setting a size here was what kept
        // labelLarge — a rung with its own tracking, written for exactly
        // this — from ever being used by anything.
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PixieTokens.rSmall)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: textTheme.bodyMedium,
      ),
    ),
    // Dialogs and sheets are stickers themselves: paper fill + thick white
    // outline against the dark barrier.
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PixieTokens.rSheet),
        side: const BorderSide(
            color: Colors.white, width: PixieTokens.stickerBorder + 1),
      ),
      backgroundColor: PixiePalette.paperCard,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PixiePalette.paperCard,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PixieTokens.rSheet)),
      ),
      showDragHandle: true,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      // "On" should not be carried by colour alone — a parent who cannot
      // tell mint from grey still has to be able to read their own
      // settings screen.
      thumbIcon: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Icon(Icons.check_rounded, color: PixiePalette.mint)
            : null,
      ),
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
