import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../ui/kid_sheet.dart';
import '../util/color_utils.dart';
import '../util/settings.dart';
import 'color_palette.dart';

/// Bottom sheet with the big kid color grid plus a most-recently-used row.
/// Picking a color selects it and closes the sheet.
Future<void> showColorPickerSheet(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: '🎨',
    title: context.l10n.colorPickerTitle,
    child: _ColorPickerBody(controller: controller),
  );
}

class _ColorPickerBody extends StatelessWidget {
  const _ColorPickerBody({required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final recents = Settings.instance.recentColors
        .map((v) => Color(v))
        .toList(growable: false);
    final grid = kidColorGrid();

    void pick(Color c) {
      controller.selectColor(c);
      Settings.instance.registerRecentColor(c);
      Navigator.of(context).pop();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot =
            ((constraints.maxWidth - 32) / kGridHues.length).clamp(36.0, 60.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recents.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('🕐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(context.l10n.colorRecent,
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final c in recents)
                        PixieColorSwatch(
                          color: c,
                          selected: controller.color == c,
                          onTap: () => pick(c),
                          slotWidth: slot,
                          slotHeight: 54,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              for (final row in grid)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in row)
                      PixieColorSwatch(
                        color: c,
                        selected: controller.color == c,
                        onTap: () => pick(c),
                        slotWidth: slot,
                        slotHeight: 50,
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
