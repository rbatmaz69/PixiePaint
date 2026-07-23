import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'bouncy.dart';
import 'pop_in.dart';

/// Kid-friendly dialog shell: big emoji header, Fredoka title, and large
/// full-width action buttons. The safe default action should be a
/// [KidDialogButton] (big, colorful); destructive/secondary actions a
/// [KidDialogTextButton] (small, subtle).
///
/// Enters with a springy scale-in (easeOutBack) and a bouncing emoji —
/// [showGeneralDialog] under the hood, behaviorally identical to
/// [showDialog] otherwise.
Future<T?> showKidDialog<T>({
  required BuildContext context,
  required String emoji,
  required String title,
  Widget? body,
  List<Widget> actions = const [],
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 340),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      child: ScaleTransition(
        scale: Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn)),
        child: child,
      ),
    ),
    pageBuilder: (context, _, _) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PopIn(
                from: 0.4,
                rotateFrom: -0.15,
                delay: const Duration(milliseconds: 120),
                duration: const Duration(milliseconds: 550),
                child: Text(emoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              if (body != null) ...[
                const SizedBox(height: 12),
                body,
              ],
              const SizedBox(height: 20),
              for (final (i, action) in actions.indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                action,
              ],
            ],
          ),
        ),
      ),
    ),
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
              const SizedBox(width: 10),
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
