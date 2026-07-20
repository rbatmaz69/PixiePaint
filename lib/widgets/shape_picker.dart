import 'package:flutter/material.dart';

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
    };

String shapeLabel(BuildContext context, ShapeKind kind) => switch (kind) {
      ShapeKind.circle => context.l10n.shapeCircle,
      ShapeKind.square => context.l10n.shapeSquare,
      ShapeKind.heart => context.l10n.shapeHeart,
      ShapeKind.star => context.l10n.shapeStar,
      ShapeKind.rainbow => context.l10n.shapeRainbow,
    };

/// Bottom sheet with one tile per shape, each previewed in the currently
/// selected color; picking one selects the shape tool with that motif.
Future<void> showShapePicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: shapeEmoji(controller.shapeKind),
    title: context.l10n.toolShapes,
    child: GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: ShapeKind.values.length,
      itemBuilder: (context, i) {
        final kind = ShapeKind.values[i];
        final selected =
            controller.tool == ToolKind.shape && controller.shapeKind == kind;
        return Bouncy(
          playTick: false,
          onTap: () {
            controller.selectShape(kind);
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
                CustomPaint(
                  size: const Size(52, 52),
                  painter: _ShapePreviewPainter(kind, controller.color),
                ),
                const SizedBox(height: 6),
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
  );
}

class _ShapePreviewPainter extends CustomPainter {
  _ShapePreviewPainter(this.kind, this.color);

  final ShapeKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = kind == ShapeKind.rainbow
        ? Offset(size.width / 2, size.height * 0.75)
        : size.center(Offset.zero);
    ShapeRenderer.drawShape(
        canvas, kind, center, size.shortestSide * 0.44, color, 4);
  }

  @override
  bool shouldRepaint(_ShapePreviewPainter old) =>
      old.kind != kind || old.color != color;
}
