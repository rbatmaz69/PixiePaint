import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../canvas/symmetry.dart';
import '../l10n/l10n.dart';
import '../ui/bouncy.dart';
import '../ui/kid_sheet.dart';
import '../ui/sticker.dart';

String symmetryEmoji(int folds) => switch (folds) {
      2 => '🦋',
      4 => '🌸',
      6 => '❄️',
      _ => '🖌️',
    };

String symmetryLabel(BuildContext context, int folds) => switch (folds) {
      2 => context.l10n.symmetryButterfly,
      4 => context.l10n.symmetryFlower,
      6 => context.l10n.symmetrySnowflake,
      _ => context.l10n.symmetryOff,
    };

/// Bottom sheet with one tile per magic-mirror mode; picking one sets the
/// fold count without changing the selected tool.
Future<void> showSymmetryPicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: symmetryEmoji(controller.symmetryFolds),
    title: context.l10n.symmetryTitle,
    child: GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: kSymmetryFolds.length,
      itemBuilder: (context, i) {
        final folds = kSymmetryFolds[i];
        final selected = controller.symmetryFolds == folds;
        return Bouncy(
          playTick: false,
          onTap: () {
            controller.selectSymmetry(folds);
            Navigator.of(context).pop();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: stickerSelectionDecoration(
              selected: selected,
              accent: const Color(0xFF7C6BF0),
              restColor: const Color(0xFFF5F0E8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(symmetryEmoji(folds),
                    style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 6),
                Text(
                  symmetryLabel(context, folds),
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
