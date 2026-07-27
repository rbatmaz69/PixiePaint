import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../ui/pixie_palette.dart';

import '../ui/motion.dart';
import '../canvas/canvas_controller.dart';
import '../canvas/shape_renderer.dart';
import '../l10n/l10n.dart';
import '../models/tool.dart';
import '../ui/bouncy.dart';
import '../ui/kid_sheet.dart';
import '../ui/sticker.dart';

String shapeEmoji(ShapeKind kind) => switch (kind) {
      ShapeKind.circle => '⭕',
      ShapeKind.square => '🟦',
      ShapeKind.heart => '💜',
      ShapeKind.star => '⭐',
      ShapeKind.rainbow => '🌈',
      ShapeKind.line => '➖',
      ShapeKind.triangle => '🔺',
      ShapeKind.oval => '🥚',
    };

String shapeLabel(BuildContext context, ShapeKind kind) => switch (kind) {
      ShapeKind.circle => context.l10n.shapeCircle,
      ShapeKind.square => context.l10n.shapeSquare,
      ShapeKind.heart => context.l10n.shapeHeart,
      ShapeKind.star => context.l10n.shapeStar,
      ShapeKind.rainbow => context.l10n.shapeRainbow,
      ShapeKind.line => context.l10n.shapeLine,
      ShapeKind.triangle => context.l10n.shapeTriangle,
      ShapeKind.oval => context.l10n.shapeOval,
    };

/// Bottom sheet with one tile per shape, each previewed in the currently
/// selected color; picking one selects the shape tool with that motif.
///
/// The filled/outline switch lives here rather than in the toolbar. It is a
/// property of the motif, not a tool of its own, and the rail is already the
/// longest strip on the screen.
Future<void> showShapePicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: shapeEmoji(controller.shapeKind),
    title: context.l10n.toolShapes,
    builder: (sheetContext) => _ShapeSheet(controller: controller),
  );
}

class _ShapeSheet extends StatefulWidget {
  const _ShapeSheet({required this.controller});

  final CanvasController controller;

  @override
  State<_ShapeSheet> createState() => _ShapeSheetState();
}

class _ShapeSheetState extends State<_ShapeSheet> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: ShapeKind.values.length,
          itemBuilder: (context, i) {
            final kind = ShapeKind.values[i];
            final selected = controller.tool == ToolKind.shape &&
                controller.shapeKind == kind;
            return Bouncy(
              playTick: false,
              onTap: () {
                controller.selectShape(kind);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: PixieMotion.select,
                curve: PixieCurves.spring,
                decoration: stickerSelectionDecoration(
                  selected: selected,
                  accent: PixiePalette.periwinkle,
                  restColor: PixiePalette.paperDeep,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(52, 52),
                      painter: _ShapePreviewPainter(kind, controller.color,
                          outline: controller.shapeOutline),
                    ),
                    const SizedBox(height: PixieTokens.gapTiny),
                    Text(
                      shapeLabel(context, kind),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            children: [
              Expanded(
                child: _FillChip(
                  label: context.l10n.shapeFilled,
                  emoji: '🟪',
                  selected: !controller.shapeOutline,
                  onTap: () => setState(() => controller.shapeOutline = false),
                ),
              ),
              const SizedBox(width: PixieTokens.gapSmall),
              Expanded(
                child: _FillChip(
                  label: context.l10n.shapeOutline,
                  emoji: '⬜',
                  selected: controller.shapeOutline,
                  onTap: () => setState(() => controller.shapeOutline = true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One of the two filled/outline chips. Deliberately the same selection
/// treatment as the tiles above it, so the row reads as part of the sheet
/// rather than as a settings control that wandered in.
class _FillChip extends StatelessWidget {
  const _FillChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      playTick: false,
      onTap: onTap,
      semanticLabel: label,
      semanticSelected: selected,
      child: AnimatedContainer(
        duration: PixieMotion.select,
        curve: PixieCurves.spring,
        padding: const EdgeInsets.symmetric(
            horizontal: PixieTokens.gap, vertical: PixieTokens.gapSmall),
        decoration: stickerSelectionDecoration(
          selected: selected,
          accent: PixiePalette.periwinkle,
          restColor: PixiePalette.paperDeep,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: PixieTokens.gapSmall),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShapePreviewPainter extends CustomPainter {
  _ShapePreviewPainter(this.kind, this.color, {this.outline = false});

  final ShapeKind kind;
  final Color color;
  final bool outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = kind == ShapeKind.rainbow
        ? Offset(size.width / 2, size.height * 0.75)
        : size.center(Offset.zero);
    ShapeRenderer.drawShape(
        canvas, kind, center, size.shortestSide * 0.44, color, 4,
        // The line lies flat in a preview: there is no drag to take a
        // direction from, and a tilted one would promise a tilt the child
        // did not choose.
        outline: outline);
  }

  @override
  bool shouldRepaint(_ShapePreviewPainter old) =>
      old.kind != kind || old.color != color || old.outline != outline;
}
