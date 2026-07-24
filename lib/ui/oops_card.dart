import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'pixie_palette.dart';

/// What a child sees when a widget subtree fails to build in a release
/// build: a soft card instead of Flutter's grey box (release) or red-and-
/// yellow stripes (debug).
///
/// Deliberately built from constants only — no `Theme.of`, no `textTheme`, no
/// gradient helper, no animation. This widget replaces a subtree that *just
/// threw*, and a broken theme or a disposed ticker is one of the plausible
/// reasons; anything it looks up could throw a second time, and an error
/// inside the error widget has nowhere left to go.
///
/// It carries no button on purpose. It stands in for one broken piece of the
/// screen, not the screen — the way out is the system back gesture, and
/// offering a button that cannot know what to pop would be a lie.
class OopsCard extends StatelessWidget {
  const OopsCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Localizations are usually there (the failure sits below MaterialApp),
    // but not always — an error above it would leave this null. German is the
    // app's fallback language anyway.
    final l10n = AppLocalizations.of(context);
    return Container(
      color: PixiePalette.paper,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🙈', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          Text(
            l10n?.oopsTitle ?? 'Ups — hier ist etwas durcheinandergeraten.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: PixiePalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.oopsBody ?? 'Geh einen Schritt zurück und probier es nochmal.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: PixiePalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}
