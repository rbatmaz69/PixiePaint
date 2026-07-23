import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/kid_dialog.dart';
import '../ui/pixie_palette.dart';
import '../ui/pop_in.dart';
import '../util/sfx.dart';
import '../widgets/parental_gate.dart';

/// The painting-break curtain a parent can switch on in the settings.
///
/// Two deliberate choices:
/// * It never interrupts the drawing. The picture underneath keeps its
///   state and has already been autosaved — the curtain only covers it.
/// * Carrying on needs the parental gate. A break a child can wave away is
///   not a break, and this is the one moment in the app where the answer
///   "no" has to come from an adult.
Future<void> showPauseCurtain(BuildContext context) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: PixiePalette.ink.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 420),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      child: child,
    ),
    pageBuilder: (context, _, _) => const _PauseCurtain(),
  );
}

class _PauseCurtain extends StatefulWidget {
  const _PauseCurtain();

  @override
  State<_PauseCurtain> createState() => _PauseCurtainState();
}

class _PauseCurtainState extends State<_PauseCurtain> {
  bool _checking = false;

  Future<void> _continue() async {
    if (_checking) return;
    setState(() => _checking = true);
    final passed = await ParentalGate.show(context);
    if (!mounted) return;
    setState(() => _checking = false);
    if (passed) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      // The system back button must not be a way around the break.
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PopIn(
                    from: 0.4,
                    rotateFrom: -0.12,
                    duration: Duration(milliseconds: 620),
                    child: Text('🌈', style: TextStyle(fontSize: 72)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.pauseTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.pauseBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 28),
                  KidDialogButton(
                    label: l10n.pauseContinue,
                    emoji: '🔓',
                    sticker: true,
                    gradient: PixieGradients.coloring,
                    onTap: _continue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.pauseSaved,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Sfx.instance.pop();
  }
}
