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

  // Five more tool accents. Nine of the fourteen tools already took their
  // highlight from here; these five sat in `tool_bar.dart` as bare values,
  // which made the accent set look smaller than it is.
  /// The trail pen.
  static const Color raspberry = Color(0xFFE91E63);

  /// The dotted pen.
  static const Color indigo = Color(0xFF5C6BC0);

  /// The twin pen.
  ///
  /// Byte-identical to türkis in the paint palette, and [slate] to grau —
  /// same deal as [gold]: one of the two is surface, the other is content,
  /// and content colors do not live here. They only happen to agree.
  static const Color teal = Color(0xFF26A69A);

  /// The eraser.
  static const Color slate = Color(0xFF90A4AE);

  /// The eyedropper.
  static const Color pine = Color(0xFF00A28C);

  /// A shade below [paper]: the resting fill of an unpicked tile, where
  /// plain white would read as "selected".
  static const Color paperDeep = Color(0xFFF5F0E8);

  /// A shade above [paper]: dialogs and sheets, which sit *on* the paper.
  static const Color paperCard = Color(0xFFFFFDF8);

  /// The hairline around a tile that is already filled with [paperDeep] —
  /// the one edge in the app that has to show against its own fill.
  static const Color paperEdge = Color(0xFFDBD2C3);

  // Light derivations for card gradients, tints and blobs.
  static const Color sunshineLight = Color(0xFFFFE9A8);
  static const Color tangerineLight = Color(0xFFFFD9BC);
  static const Color bubblegumLight = Color(0xFFFFD2E4);
  static const Color grapeLight = Color(0xFFE2D5FF);
  static const Color skyLight = Color(0xFFC9ECFF);
  static const Color mintLight = Color(0xFFCCF3E0);

  // Three more light tints, so that all ten picture categories take their
  // tone from one place instead of seven.
  /// Weltraum.
  static const Color periwinkleLight = Color(0xFFE2E0FF);

  /// Bauernhof — the only warm-neutral tint, and the reason it needs its
  /// own name: nothing else in here is that close to hay.
  static const Color strawLight = Color(0xFFE8E3CF);

  /// Jahreszeiten.
  static const Color berryLight = Color(0xFFFFE0DC);

  /// Two mid-tones that exist only as the far end of a gradient.
  static const Color blushLight = Color(0xFFFFB7CF);
  static const Color grapeMid = Color(0xFFC5A8F2);

  // The five whispers of paper. Each is the far end of one screen
  // background, where [paper] fades into a hint of that screen's feature
  // tint — never used alone, and never anywhere else.
  static const Color paperWarm = Color(0xFFFFF0E4);
  static const Color paperViolet = Color(0xFFF0EBFA);
  static const Color paperSun = Color(0xFFFFF3D9);
  static const Color paperMint = Color(0xFFE9F7EE);
  static const Color paperPeach = Color(0xFFFFEBE0);

  // ---------------------------------------------------------------------
  // Dusk: the evening face of the *ground* only.
  //
  // Deliberately not a dark theme. The white sheet a child paints on is
  // picture, not surface — every export is laid on white, the sixty-eight
  // line drawings are black, and a gallery thumbnail is a white rectangle.
  // Turning those dark would mean a child paints yellow on navy and shares
  // yellow on white, which is not a mode but a bug.
  //
  // So only the backdrop changes, and the stickers on it stay white. They
  // read *better* in the evening, not worse.

  /// The evening ground, in place of [paper].
  static const Color dusk = Color(0xFF2A2337);

  /// A shade below [dusk], for the far end of a gradient.
  static const Color duskDeep = Color(0xFF1E1929);

  /// The five whispers of dusk, one per screen — the same five features as
  /// the paper ones above, at the same distance from their ground.
  static const Color duskWarm = Color(0xFF322638);
  static const Color duskViolet = Color(0xFF2E2743);
  static const Color duskSun = Color(0xFF332B31);
  static const Color duskMint = Color(0xFF242C35);
  static const Color duskPeach = Color(0xFF34262F);

  /// What [ink] is on paper, chalk is on dusk: the colour of text and marks
  /// lying directly on the ground. Never pure white, for the same reason
  /// [ink] is never pure black.
  static const Color chalk = Color(0xFFF3EDF7);
}
