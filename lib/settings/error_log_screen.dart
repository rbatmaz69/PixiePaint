import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/error_log.dart';
import '../widgets/parental_gate.dart';

/// The parents' problem report: what the app caught going wrong, in the order
/// it happened, newest first.
///
/// Deliberately plain. This is the one screen in PixiePaint written for an
/// adult in a bad mood — something did not work, and the useful answer is a
/// timestamp and a message, not an animation. The friendly part is the empty
/// state, because that is the one a parent should normally see.
class ErrorLogScreen extends StatefulWidget {
  const ErrorLogScreen({super.key});

  @override
  State<ErrorLogScreen> createState() => _ErrorLogScreenState();
}

class _ErrorLogScreenState extends State<ErrorLogScreen> {
  bool _busy = false;

  /// Hands the report to the system share sheet. Reaching this screen already
  /// required the parental gate, but the file leaves the device, so it asks
  /// again on its own — the same rule the backup export follows: the safety
  /// does not depend on where the button happens to be mounted.
  Future<void> _share() async {
    if (_busy || ErrorLog.instance.isEmpty) return;
    if (!await ParentalGate.show(context)) return;
    if (!mounted) return;
    final note = context.l10n.errorLogShareNote;
    setState(() => _busy = true);
    try {
      await shareErrorReport(note: note);
    } catch (_) {
      // A missing share sheet is not worth an error dialog on the error
      // screen.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    if (_busy || ErrorLog.instance.isEmpty) return;
    final l10n = context.l10n;
    final confirmed = await showKidDialog<bool>(
      context: context,
      emoji: '🧹',
      title: l10n.errorLogClearConfirm,
      actions: [
        Builder(
          builder: (dialogContext) => KidDialogButton(
            label: l10n.storageDeleteKeep,
            emoji: '💚',
            onTap: () => Navigator.pop(dialogContext, false),
          ),
        ),
        Builder(
          builder: (dialogContext) => KidDialogTextButton(
            label: l10n.storageDeleteGo,
            onTap: () => Navigator.pop(dialogContext, true),
          ),
        ),
      ],
    );
    if (confirmed != true) return;
    // The list is empty in memory the moment this returns; the file catches
    // up on its own queue. Waiting for the disk before redrawing would make
    // an emptied list look full for as long as the write takes — and it is
    // the same fire-and-forget writing the settings and the reward progress
    // have always done.
    unawaited(ErrorLog.instance.clear());
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = ErrorLog.instance.entries;
    return Scaffold(
      body: BlobBackground(
        gradient: PixieGradients.homeBg,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              PixieHeader(
                emoji: '🧾',
                title: l10n.errorLogTitle,
                accent: PixiePalette.sky,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    StickerCard(
                      color: Colors.white,
                      radius: 24,
                      shadowColor: PixiePalette.sky,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.errorLogCount(entries.length),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.errorLogHint,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: PixiePalette.ink
                                        .withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (entries.isEmpty)
                      _EmptyState(text: l10n.errorLogEmpty)
                    else ...[
                      for (final entry in entries) _EntryCard(entry: entry),
                      const SizedBox(height: 8),
                      KidDialogButton(
                        label: l10n.errorLogShare,
                        emoji: '📤',
                        sticker: true,
                        onTap: _busy ? () {} : _share,
                      ),
                      const SizedBox(height: 10),
                      KidDialogTextButton(
                        label: l10n.errorLogClear,
                        onTap: _busy ? () {} : _clear,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          StickerEmoji('🎉', size: 44, shadowColor: PixiePalette.mint),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// One entry: time and origin as the heading, the message below, and the
/// stack only when a parent asks for it — the list stays scannable, and the
/// detail is one tap away for whoever ends up reading the report.
class _EntryCard extends StatefulWidget {
  const _EntryCard({required this.entry});

  final ErrorEntry entry;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  bool _open = false;

  String _time(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}. ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final l10n = context.l10n;
    final mono = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontFamily: 'monospace', color: PixiePalette.ink);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Bouncy(
        onTap: entry.stack.isEmpty
            ? null
            : () => setState(() => _open = !_open),
        playTick: false,
        minSize: 0,
        child: StickerCard(
          color: Colors.white,
          radius: 18,
          shadowColor: PixiePalette.grape,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_time(entry.time)} · ${entry.origin.name}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (entry.count > 1)
                    Text(
                      l10n.errorLogRepeat(entry.count),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: PixiePalette.berry),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(entry.message, style: mono),
              if (entry.detail != null) ...[
                const SizedBox(height: 4),
                Text(entry.detail!, style: mono),
              ],
              if (_open && entry.stack.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(entry.stack, style: mono),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
