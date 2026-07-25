/// Where we are in a row of things, as dots.
///
/// Readable across a room and without reading at all, which a "4 / 17"
/// would not be — which is why both places that need it (the welcome cards
/// and the slideshow) reach for dots rather than a number. They used to
/// build their own, with the same numbers and different colors.
library;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'pixie_palette.dart';

class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.index,
    this.activeColor = PixiePalette.grape,
    this.restColor,
  });

  final int count;
  final int index;

  final Color activeColor;

  /// The inactive dots; defaults to a faint wash of the ink color. The
  /// slideshow passes white — it sits on a dark frame, where ink would
  /// disappear.
  final Color? restColor;

  /// Beyond this the row becomes a window that slides with the active dot:
  /// forty dots on a phone in landscape is a dotted line, not a count.
  static const int maxDots = 7;

  @override
  Widget build(BuildContext context) {
    final shown = count < maxDots ? count : maxDots;
    // Keep the active dot in the middle where the row is long enough, and
    // let it travel inside a stationary window near either end.
    final first =
        count <= maxDots ? 0 : (index - maxDots ~/ 2).clamp(0, count - maxDots);
    final rest = restColor ?? PixiePalette.ink.withValues(alpha: 0.2);
    return Semantics(
      // A dot row says nothing out loud; this is the sentence for it.
      label: '${index + 1} / $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = first; i < first + shown; i++)
            AnimatedContainer(
              duration: PixieMotion.select,
              curve: PixieCurves.settle,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? activeColor : rest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
