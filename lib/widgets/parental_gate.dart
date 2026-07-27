import 'dart:math';
import '../ui/app_theme.dart';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/kid_dialog.dart';

/// Simple multiplication question that small children can't answer.
/// Returns true if the adult solved it (3 attempts allowed).
class ParentalGate {
  /// How long one solved question stays good for.
  ///
  /// Fifteen places ask, and a parent tidying up the gallery hits four or
  /// five of them in a row: share this one, print that one, throw the blurry
  /// one away. Doing the arithmetic every time is where people give up on a
  /// feature. Three minutes is short enough that the child who wandered off
  /// and came back does not walk through an open door.
  static const Duration _memory = Duration(minutes: 3);

  static DateTime? _passedAt;

  /// [remember] false asks every single time and leaves no trace — for the
  /// one caller where the gate is the lock itself rather than the handle on
  /// a parent's door. See `showPauseCurtain`.
  static Future<bool> show(BuildContext context, {bool remember = true}) async {
    if (remember) {
      final passed = _passedAt;
      if (passed != null && DateTime.now().difference(passed) < _memory) {
        return true;
      }
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _GateDialog(),
    );
    if (result == true && remember) _passedAt = DateTime.now();
    return result ?? false;
  }

  /// Back to a fresh install, like `Settings.resetForTest`. Without it one
  /// test's solved question makes the next test's gate wave everything
  /// through, and a test that means to prove the gate stands there passes
  /// for the wrong reason.
  @visibleForTesting
  static void resetForTest() => _passedAt = null;
}

class _GateDialog extends StatefulWidget {
  const _GateDialog();

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  late int a;
  late int b;
  int attempts = 0;
  String? error;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rng = Random();
    a = 6 + rng.nextInt(4); // 6..9
    b = 3 + rng.nextInt(7); // 3..9
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (int.tryParse(controller.text.trim()) == a * b) {
      Navigator.of(context).pop(true);
      return;
    }
    attempts++;
    if (attempts >= 3) {
      // Say so before closing. A parent who mistyped twice while a child
      // pulled at their sleeve used to land back on the previous screen
      // with no explanation at all, unable to tell a refusal from a tap
      // the app had simply not noticed.
      await showKidNotice(
        context,
        emoji: '🔒',
        title: context.l10n.gateGaveUpTitle,
        body: context.l10n.gateGaveUp,
        okLabel: context.l10n.okAction,
      );
      if (!mounted) return;
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      error = context.l10n.gateWrong;
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('🔒',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 48)),
              const SizedBox(height: PixieTokens.gapSmall),
              Text(context.l10n.gateTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: PixieTokens.gap),
              Text(context.l10n.gateBody, textAlign: TextAlign.center),
              const SizedBox(height: PixieTokens.gap),
              Text(context.l10n.gateQuestion(a, b),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: PixieTokens.gap),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onSubmitted: (_) => _check(),
                decoration: InputDecoration(
                  hintText: context.l10n.gateHint,
                  errorText: error,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PixieTokens.rSmall)),
                ),
              ),
              const SizedBox(height: PixieTokens.gapLarge),
              KidDialogButton(
                label: context.l10n.gateContinue,
                onTap: _check,
              ),
              const SizedBox(height: PixieTokens.gapTiny),
              KidDialogTextButton(
                label: context.l10n.gateCancel,
                onTap: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
