import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'bouncy.dart';
import 'motion.dart';
import 'pop_in.dart';

/// Kid-friendly dialog shell: big emoji header, Fredoka title, and large
/// full-width action buttons. The safe default action should be a
/// [KidDialogButton] (big, colorful); destructive/secondary actions a
/// [KidDialogTextButton] (small, subtle).
///
/// Enters with a springy scale-in (easeOutBack) and a bouncing emoji —
/// [showGeneralDialog] under the hood, behaviorally identical to
/// [showDialog] otherwise.
///
/// [actions] is handed the dialog route's own context, which is what
/// `Navigator.pop` needs to close *this* dialog and hand back a result. It
/// is a builder rather than a plain list for exactly that reason: the
/// caller's context sits above the route and cannot be popped safely, so
/// every call site used to wrap each button in its own `Builder` to reach
/// down for one. `showKidSheet` works the same way.
Future<T?> showKidDialog<T>({
  required BuildContext context,
  required String emoji,
  required String title,
  Widget? body,
  List<Widget> Function(BuildContext dialogContext)? actions,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: PixieTokens.scrim(0.54),
    transitionDuration: PixieMotion.enter,
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: PixieCurves.enter),
      child: ScaleTransition(
        scale: Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(
            parent: anim,
            curve: PixieCurves.spring,
            reverseCurve: PixieCurves.exit)),
        child: child,
      ),
    ),
    pageBuilder: (context, _, _) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        // Scrolls when it has to. The column shrink-wraps as long as it
        // fits, which is the normal case; at the largest system font a
        // dialog with two sentences and a button is taller than a small
        // phone, and until this was here it simply got clipped — the way
        // out of the dialog was the part that fell off the bottom.
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PopIn(
                  from: 0.4,
                  rotateFrom: -0.15,
                  delay: PixieMotion.emojiDelay,
                  child: Text(emoji,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: PixieTokens.gapSmall),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                if (body != null) ...[
                  const SizedBox(height: PixieTokens.gap),
                  body,
                ],
                const SizedBox(height: PixieTokens.gapLarge),
                for (final (i, action)
                    in (actions?.call(context) ?? const <Widget>[]).indexed) ...[
                  if (i > 0) const SizedBox(height: PixieTokens.gapSmall),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Says one thing and offers one way out — the shape most of this app's
/// dialogs actually have ("saved to photos", "that didn't work", "here is
/// what this sticker pack is").
///
/// Nothing a [showKidDialog] call could not spell out; it just spells it out
/// eight times otherwise, and the interesting part (the sentence a child or
/// parent reads) drowns in the button plumbing. [body] takes plain text
/// because that is all any of those places pass — reach for [showKidDialog]
/// directly the moment a dialog needs a widget or a second choice.
Future<void> showKidNotice(
  BuildContext context, {
  required String emoji,
  required String title,
  required String okLabel,
  String? body,
  String? okEmoji,
}) {
  return showKidDialog<void>(
    context: context,
    emoji: emoji,
    title: title,
    body: body == null ? null : Text(body, textAlign: TextAlign.center),
    actions: (pop) => [
      KidDialogButton(
        label: okLabel,
        emoji: okEmoji,
        onTap: () => Navigator.pop(pop),
      ),
    ],
  );
}

/// Big, colorful full-width dialog button — the safe/primary choice.
/// With [sticker] it gains the thick white outline + colored shadow, for
/// standalone CTAs outside dialogs.
class KidDialogButton extends StatelessWidget {
  const KidDialogButton({
    super.key,
    required this.label,
    required this.onTap,
    this.emoji,
    this.gradient,
    this.sticker = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? emoji;
  final Gradient? gradient;
  final bool sticker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shadowColor = gradient is LinearGradient
        ? (gradient as LinearGradient).colors.last
        : scheme.primaryContainer;
    return Bouncy(
      onTap: onTap,
      minSize: 56,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? scheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(PixieTokens.rSmall + 4),
          border: sticker
              ? Border.all(
                  color: Colors.white, width: PixieTokens.stickerBorder)
              : null,
          boxShadow: sticker ? PixieTokens.softShadow(shadowColor) : null,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: PixieTokens.gapSmall),
            ],
            Flexible(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small, subtle dialog action — for cancel/destructive choices that should
/// never be the eye-catcher.
class KidDialogTextButton extends StatelessWidget {
  const KidDialogTextButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }
}
