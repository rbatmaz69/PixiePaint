import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Simple multiplication question that small children can't answer.
/// Returns true if the adult solved it (3 attempts allowed).
class ParentalGate {
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _GateDialog(),
    );
    return result ?? false;
  }
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

  void _check() {
    if (int.tryParse(controller.text.trim()) == a * b) {
      Navigator.of(context).pop(true);
      return;
    }
    attempts++;
    if (attempts >= 3) {
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
    return AlertDialog(
      title: Text(context.l10n.gateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.gateBody),
          const SizedBox(height: 12),
          Text(context.l10n.gateQuestion(a, b),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _check(),
            decoration: InputDecoration(
              hintText: context.l10n.gateHint,
              errorText: error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.gateCancel),
        ),
        FilledButton(
          onPressed: _check,
          child: Text(context.l10n.gateContinue),
        ),
      ],
    );
  }
}
