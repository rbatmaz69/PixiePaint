/// The sheet of paper a picture sits on.
///
/// Two screens draw the same thing: the canvas while it loads a picture,
/// and the time-lapse while it repaints one. Both used to carry their own
/// white rounded box with a hand-written shadow — the same numbers, twice,
/// and neither of them the app's shadow token. This is that sheet, once.
library;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'pixie_palette.dart';

class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.child,
    required this.aspectRatio,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(24),
  });

  final Widget child;

  /// From the picture's own size, never from the canvas constants — older
  /// or future works may have been saved at other dimensions.
  final double aspectRatio;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Radius of the sheet and, eight points tighter, of the picture inside
  /// it — the paper is what has the rounded corners, the drawing merely
  /// stops short of them.
  static const double radius = PixieTokens.rTile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: margin,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              // White in both modes. This is the picture, not a surface —
              // see the same note on the live canvas.
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: PixieTokens.softShadow(PixiePalette.ink),
            ),
            padding: padding,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
