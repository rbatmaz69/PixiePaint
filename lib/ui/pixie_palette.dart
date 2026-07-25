import 'dart:ui';

/// The one named palette of the sticker-book design language. Every UI
/// tint, gradient, blob, accent and shadow color derives from here —
/// content colors (paint palette, rainbow strokes) deliberately do not.
abstract final class PixiePalette {
  // Core stickers — vivid but soft.
  static const Color sunshine = Color(0xFFFFC94D);
  static const Color tangerine = Color(0xFFFF9B54);
  static const Color bubblegum = Color(0xFFFF7BAC);
  static const Color grape = Color(0xFF9B6DFF);
  static const Color sky = Color(0xFF56C3F7);
  static const Color mint = Color(0xFF5FD6A2);
  static const Color berry = Color(0xFFEF5D7F);

  /// Warm paper — the app's ground everything is stuck onto.
  static const Color paper = Color(0xFFFFF9F0);

  /// Warm dark purple for text and doodles — never plain black.
  static const Color ink = Color(0xFF4A3A5C);

  // Accents that had escaped: each of these was a bare 0xFF… repeated at
  // two to seven call sites, which is how a palette quietly stops being
  // the one place colors live.
  /// Shapes and the magic mirror.
  static const Color periwinkle = Color(0xFF7C6BF0);

  /// Neon pen, stickers, the sticker picker's accent.
  static const Color amber = Color(0xFFFFB020);

  /// The paint bucket and its pattern picker.
  static const Color jade = Color(0xFF2BB68A);

  /// Sparkle on a freshly placed sticker.
  ///
  /// The glitter *stroke* in `stroke_renderer.dart` carries the same value
  /// and deliberately stays there: that one is paint on the picture, and
  /// content colors do not live here.
  static const Color gold = Color(0xFFFFE082);

  /// A shade below [paper]: the resting fill of an unpicked tile, where
  /// plain white would read as "selected".
  static const Color paperDeep = Color(0xFFF5F0E8);

  /// A shade above [paper]: dialogs and sheets, which sit *on* the paper.
  static const Color paperCard = Color(0xFFFFFDF8);

  // Light derivations for card gradients, tints and blobs.
  static const Color sunshineLight = Color(0xFFFFE9A8);
  static const Color tangerineLight = Color(0xFFFFD9BC);
  static const Color bubblegumLight = Color(0xFFFFD2E4);
  static const Color grapeLight = Color(0xFFE2D5FF);
  static const Color skyLight = Color(0xFFC9ECFF);
  static const Color mintLight = Color(0xFFCCF3E0);

  /// Two mid-tones that exist only as the far end of a gradient.
  static const Color blushLight = Color(0xFFFFB7CF);
  static const Color grapeMid = Color(0xFFC5A8F2);
}
