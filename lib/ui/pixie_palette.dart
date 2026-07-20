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

  // Light derivations for card gradients, tints and blobs.
  static const Color sunshineLight = Color(0xFFFFE9A8);
  static const Color tangerineLight = Color(0xFFFFD9BC);
  static const Color bubblegumLight = Color(0xFFFFD2E4);
  static const Color grapeLight = Color(0xFFE2D5FF);
  static const Color skyLight = Color(0xFFC9ECFF);
  static const Color mintLight = Color(0xFFCCF3E0);
}
