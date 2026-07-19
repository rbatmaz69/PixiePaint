import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/stamp.dart';
import '../ui/bouncy.dart';
import '../ui/kid_sheet.dart';

/// Bottom sheet with a grid of emoji stamps; picking one selects the stamp
/// tool with that motif.
Future<void> showStampPicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: controller.stampEmoji,
    title: context.l10n.toolSticker,
    child: GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 80,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: kStamps.length,
      itemBuilder: (context, i) {
        final emoji = kStamps[i];
        final selected = controller.stampEmoji == emoji;
        return Bouncy(
          playTick: false,
          onTap: () {
            controller.selectStamp(emoji);
            Navigator.of(context).pop();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(emoji,
                  style: TextStyle(fontSize: selected ? 40 : 36)),
            ),
          ),
        );
      },
    ),
  );
}
