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
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: PixiePalette.ink),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
