import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'app_theme.dart';
import 'blob_background.dart';
import 'loading_pixie.dart';
import 'pixie_header.dart';

/// A screen that is still loading, or that failed to load — with the way out
/// present either way.
///
/// Four pickers used to treat "no data yet" and "it threw" as the same thing:
/// a bouncing emoji, no title, and — in the picture picker, which is the
/// very first screen a new child sees — no header and therefore no back
/// arrow at all. A file that fails to parse left the pixie hopping forever
/// with nothing to tap.
///
/// So: the header is here in both states, because a screen a child cannot
/// leave is worse than a screen that admits it is broken. And the two states
/// look different, because "wait a moment" and "this did not work" are not
/// the same message.
class PixieWaitScreen extends StatelessWidget {
  const PixieWaitScreen({
    super.key,
    required this.emoji,
    required this.title,
    required this.gradient,
    this.accent,
    this.label,
    this.failed = false,
  });

  final String emoji;
  final String title;
  final LinearGradient gradient;
  final Color? accent;

  /// What is being waited for. Worth saying — an emoji hopping on its own
  /// does not explain itself, and [LoadingPixie] has taken a label since
  /// v8.4 without most callers passing one.
  final String? label;

  /// The load failed and will not arrive.
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        gradient: gradient,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              PixieHeader(
                emoji: emoji,
                title: title,
                accent: accent,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Center(
                  child: failed
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🙈',
                                  style: TextStyle(fontSize: 56)),
                              const SizedBox(height: PixieTokens.gap),
                              Text(
                                context.l10n.oopsTitle,
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: PixieTokens.gapSmall),
                              Text(
                                context.l10n.oopsBody,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : LoadingPixie(emoji: emoji, label: label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
