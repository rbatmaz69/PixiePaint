import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'bouncy.dart';
import 'pixie_palette.dart';

/// A surface that reads as a sticker stuck onto the paper: thick white
/// outline, soft colored shadow and an optional deterministic tilt.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.gradient,
    this.color,
    this.radius = PixieTokens.rCard,
    this.shadowColor,
    this.tiltIndex,
    this.borderWidth = PixieTokens.stickerBorder,
    this.padding,
    this.width,
    this.height,
  });

  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final double radius;
  final Color? shadowColor;

  /// Grid/list slot for [PixieTokens.stickerTilt]; null = no tilt.
  final int? tiltIndex;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Color shadow = shadowColor ??
        (gradient is LinearGradient
            ? (gradient as LinearGradient).colors.last
            : (color ?? PixiePalette.ink));
    Widget card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        border: Border.all(color: Colors.white, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: PixieTokens.softShadow(shadow),
      ),
      child: child,
    );
    final tilt = tiltIndex;
    if (tilt != null) {
      card = Transform.rotate(angle: PixieTokens.stickerTilt(tilt), child: card);
    }
    return card;
  }
}

/// White round sticker button for chrome (back, share, settings, undo…):
/// white circle, colored soft shadow, built-in Bouncy press.
class StickerCircleButton extends StatelessWidget {
  const StickerCircleButton({
    super.key,
    required this.onTap,
    this.icon,
    this.emoji,
    this.child,
    this.tooltip,
    this.size = 48,
    this.accent,
    this.enabled = true,
    this.playTick = true,
  });

  final VoidCallback? onTap;
  final IconData? icon;
  final String? emoji;

  /// Custom content (overrides [icon]/[emoji]).
  final Widget? child;
  final String? tooltip;
  final double size;

  /// Tints the shadow so the button belongs to its feature.
  final Color? accent;
  final bool enabled;
  final bool playTick;

  @override
  Widget build(BuildContext context) {
    final Widget content = child ??
        (emoji != null
            ? Text(emoji!, style: TextStyle(fontSize: size * 0.45))
            : Icon(
                icon,
                size: size * 0.5,
                color: enabled
                    ? PixiePalette.ink.withValues(alpha: 0.7)
                    : PixiePalette.ink.withValues(alpha: 0.3),
              ));
    Widget button = Bouncy(
      onTap: enabled ? onTap : null,
      playTick: playTick,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: enabled
              ? PixieTokens.softShadow(accent ?? PixiePalette.ink)
              : null,
        ),
        child: content,
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// Emoji on a white squircle chip with a tilt — the "sticker outline".
/// (A true white outline via shadows/stroke doesn't work for color emoji
/// glyphs, so the chip carries the sticker look.)
class StickerEmoji extends StatelessWidget {
  const StickerEmoji(
    this.emoji, {
    super.key,
    this.size = 40,
    this.tiltIndex,
    this.shadowColor,
  });

  final String emoji;
  final double size;
  final int? tiltIndex;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    Widget chip = Container(
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.35),
        boxShadow:
            PixieTokens.softShadow(shadowColor ?? PixiePalette.grape),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size)),
    );
    final tilt = tiltIndex;
    if (tilt != null) {
      chip = Transform.rotate(angle: PixieTokens.stickerTilt(tilt), child: chip);
    }
    return chip;
  }
}
