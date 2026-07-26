import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

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
    builder: (_) => _ColorPickerBody(controller: controller),
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
    final names = paletteColorNames(context);

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
                    const SizedBox(width: PixieTokens.gapSmall),
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
                const SizedBox(height: PixieTokens.gapSmall),
              ],
              // The grid is generated, so every swatch here knows what it
              // was built from and is named after that column rather than
              // after a guess. The last row is the neutrals, which have
              // their own list of names.
              for (var r = 0; r < grid.length; r++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < grid[r].length; i++)
                      PixieColorSwatch(
                        color: grid[r][i],
                        selected: controller.color == grid[r][i],
                        onTap: () => pick(grid[r][i]),
                        slotWidth: slot,
                        slotHeight: 50,
                        label: names[r == grid.length - 1
                            ? kGridNeutralNames[i]
                            : kGridHueNames[i]],
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
