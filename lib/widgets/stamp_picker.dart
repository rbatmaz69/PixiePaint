import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../models/stamp.dart';

/// Bottom sheet with a grid of emoji stamps; picking one selects the stamp
/// tool with that motif.
Future<void> showStampPicker(
    BuildContext context, CanvasController controller) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 72,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: kStamps.length,
        itemBuilder: (context, i) {
          final emoji = kStamps[i];
          final selected = controller.stampEmoji == emoji;
          return Material(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                controller.selectStamp(emoji);
                Navigator.of(context).pop();
              },
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 34)),
              ),
            ),
          );
        },
      ),
    ),
  );
}
