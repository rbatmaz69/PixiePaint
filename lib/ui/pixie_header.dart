import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'pixie_palette.dart';
import 'sticker.dart';

/// The sticker-book screen header: back button, tilted emoji sticker and a
/// big friendly title. Replaces default AppBars and hand-built headers.
class PixieHeader extends StatelessWidget {
  const PixieHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.onBack,
    this.trailing,
    this.accent,
  });

  final String emoji;
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Tints the emoji chip's shadow.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          if (onBack != null) ...[
            StickerCircleButton(
              onTap: onBack,
              icon: Icons.arrow_back_rounded,
              tooltip: context.l10n.back,
              accent: accent,
            ),
            const SizedBox(width: 10),
          ],
          StickerEmoji(emoji,
              size: 26, tiltIndex: 1, shadowColor: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: PixiePalette.ink),
                ),
                // A short crayon underline in the screen's own color. It is
                // the one mark that says "you are here" without any reading
                // — and it sits under the title's start, not centered, so
                // it reads as underlined rather than as a divider.
                const SizedBox(height: 3),
                Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (accent ?? PixiePalette.grape)
                        .withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
