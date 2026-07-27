import 'package:flutter/material.dart';

import '../util/color_utils.dart';
import 'app_theme.dart';
import 'motion.dart';
import 'pixie_palette.dart';

/// The accent a dish may wear for [c].
///
/// A white dish casting a white shadow on cream paper is no dish at all,
/// so white and the very light tones borrow ink instead. This lives beside
/// [SelectionCradle] rather than inside it: the dish stays dumb — it tints
/// what it is given — and the rule its callers share stays in one place.
Color cradleAccent(Color c) => needsBorder(c) ? PixiePalette.ink : c;

/// The white dish the chosen thing sits in, which slides from slot to slot
/// instead of appearing in one and disappearing from another.
///
/// A row of swatches each animating its own selection is a row of things
/// changing at once; one dish gliding is a single movement the eye can
/// follow, and it is what answers "where did my colour go?".
///
/// The trick that makes it cheap is the only thing it demands: **every slot
/// must be the same width**. The target is then `slot * slotWidth` — no
/// keys, no measuring, no extra layout pass. Both palettes that use it
/// qualify: 56 dp in the paint palette, 64 in the numbered one.
///
/// The toolbar rail does not have one, and the reason is not the slots —
/// v8.8 put its size, mirror and action buttons on the tools' width, and a
/// vertical variant of this was built and fitted. It was then taken out
/// again after looking at it: the palettes lie on cream paper, where a
/// white dish reads, while the rail stands on a white bar, where it is a
/// white tile on white and only its shadow shows. Same lesson as the
/// vanishing dish under a white swatch in v8.6 — a dish needs a ground that
/// is not already the dish's colour. The rail keeps its per-button accent
/// ring, which is legible there.
///
/// Put it in a [Stack] *before* the row, so it paints behind, and inside
/// the scroll view's content, so it travels with the row rather than
/// sliding out from under it. The row is then the Stack's only
/// non-positioned child and gives it its size.
class SelectionCradle extends StatelessWidget {
  const SelectionCradle({
    super.key,
    required this.slot,
    required this.accent,
    required this.slotWidth,
    required this.size,
  });

  /// Which slot to sit in; null means nothing is picked, and the dish fades
  /// out where it stands rather than sliding home to slot zero.
  final int? slot;

  /// Tints the shadow, so the dish belongs to what it is holding.
  final Color accent;

  final double slotWidth;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      // Gliding *is* the movement here, so with "reduce motion" on the dish
      // simply is where it belongs. One of the few places where the honest
      // reduced form is an instant jump rather than a fade.
      duration: motionDuration(context, PixieMotion.select),
      curve: PixieCurves.spring,
      left: (slot ?? 0) * slotWidth,
      top: 0,
      bottom: 0,
      width: slotWidth,
      child: Center(
        child: AnimatedOpacity(
          opacity: slot == null ? 0 : 1,
          duration: motionDuration(context, PixieMotion.select),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(PixieTokens.rSmall),
              boxShadow: PixieTokens.softShadow(accent),
            ),
          ),
        ),
      ),
    );
  }
}
