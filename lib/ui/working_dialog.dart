import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'kid_dialog.dart';
import 'loading_pixie.dart';

/// Runs [work] behind a modal "just a moment" card, and says so if it fails.
///
/// The parents' exports — share, print, save to photos — all reload a PNG
/// from disk, re-rasterize the line art and encode 2048x1536, and every one
/// of them did it in silence. The parent had just solved an arithmetic
/// problem to get here; a second of nothing afterwards is not
/// distinguishable from a tap the app never saw.
///
/// Two of them were worse than silent: they swallowed the exception whole
/// (`catch (_) {}`), so a printer that refused the job looked exactly like
/// a button that did not work.
///
/// The shape is lifted from the backup flow, which had it right first: the
/// dialog is deliberately *not* awaited, and [dialogOpen] tracks whether it
/// still needs popping — awaiting it would mean waiting for the parent to
/// dismiss a card that is supposed to dismiss itself.
///
/// Returns the value of [work], or null if it threw.
Future<T?> runWithWorkingDialog<T>({
  required BuildContext context,
  required String emoji,
  required String title,
  required String failedTitle,
  required Future<T> Function() work,
}) async {
  final l10n = context.l10n;
  var dialogOpen = true;
  unawaited(showKidDialog<void>(
    context: context,
    emoji: emoji,
    barrierDismissible: false,
    title: title,
    body: LoadingPixie(emoji: emoji),
  ).then((_) => dialogOpen = false));

  void close() {
    if (context.mounted && dialogOpen) Navigator.of(context).pop();
    dialogOpen = false;
  }

  try {
    final result = await work();
    close();
    return result;
  } catch (_) {
    close();
    if (context.mounted) {
      await showKidNotice(
        context,
        emoji: '😕',
        title: failedTitle,
        okLabel: l10n.okAction,
        okEmoji: '👍',
      );
    }
    return null;
  }
}
