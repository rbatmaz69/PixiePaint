import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../canvas/mask_path.dart';
import '../l10n/l10n.dart';
import '../models/mask.dart';
import '../models/tool.dart';
import '../ui/app_theme.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/kid_sheet.dart';
import '../ui/motion.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import 'shape_picker.dart' show shapeLabel;

/// The masking-tape sheet: which shape, which side, and — once a piece is
/// stuck down — the way to pull it off again.
///
/// Peeling lives here rather than on a button over the picture, because
/// nothing that *does* something is allowed to sit on the paper (v8.7). The
/// tape button in the rail is where a child put the tape on, so it is where
/// they look to take it off.
Future<void> showTapePicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: '🩹',
    title: context.l10n.toolTape,
    builder: (_) => _TapeSheet(controller: controller),
  );
}

class _TapeSheet extends StatefulWidget {
  const _TapeSheet({required this.controller});

  final CanvasController controller;

  @override
  State<_TapeSheet> createState() => _TapeSheetState();
}

class _TapeSheetState extends State<_TapeSheet> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            controller.tape == null ? l10n.tapeHint : l10n.tapeStuckHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 110,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: kTapeKinds.length,
          itemBuilder: (context, i) {
            final kind = kTapeKinds[i];
            final selected = controller.tool == ToolKind.tape &&
                controller.tapeKind == kind;
            return Bouncy(
              playTick: false,
              semanticLabel: shapeLabel(context, kind),
              semanticSelected: selected,
              onTap: () {
                controller.selectTapeKind(kind);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: PixieMotion.select,
                curve: PixieCurves.spring,
                decoration: stickerSelectionDecoration(
                  selected: selected,
                  accent: PixiePalette.mint,
                  restColor: PixiePalette.paperDeep,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(52, 52),
                      painter: _TapePreviewPainter(
                          kind, inverted: controller.tapeInverted),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _SideChip(
                  label: l10n.tapeInside,
                  emoji: '🎯',
                  selected: !controller.tapeInverted,
                  onTap: () => setState(
                      () => controller.selectTapeSide(inverted: false)),
                ),
              ),
              const SizedBox(width: PixieTokens.gapSmall),
              Expanded(
                child: _SideChip(
                  label: l10n.tapeOutside,
                  emoji: '🛡️',
                  selected: controller.tapeInverted,
                  onTap: () => setState(
                      () => controller.selectTapeSide(inverted: true)),
                ),
              ),
            ],
          ),
        ),
        if (controller.tape != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: KidDialogButton(
              emoji: '✋',
              label: l10n.tapePeel,
              gradient: PixieGradients.gallery,
              onTap: () {
                controller.peelTape();
                Navigator.pop(context);
              },
            ),
          )
        else
          const SizedBox(height: PixieTokens.gap),
      ],
    );
  }
}

/// A tile preview: the motif as tape, with the protected side shaded the way
/// it will be on the paper. The two side chips change every tile at once,
/// which is what says the choice is about the tape and not about one motif.
class _TapePreviewPainter extends CustomPainter {
  _TapePreviewPainter(this.kind, {required this.inverted});

  final ShapeKind kind;
  final bool inverted;

  @override
  void paint(Canvas canvas, Size size) {
    final mask = Mask(
      kind: kind,
      x: size.width / 2,
      y: size.height / 2,
      radius: size.width * 0.36,
      // A strip drawn flat looks like a mistake at tile size; on the slant
      // it reads as a piece of tape.
      angle: kind == ShapeKind.line ? -0.5 : 0,
      inverted: inverted,
    );
    drawTape(canvas, mask, size);
  }

  @override
  bool shouldRepaint(_TapePreviewPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.inverted != inverted;
}

/// Inside / outside. Same treatment as the shape sheet's filled/outline
/// chips, because it is the same kind of choice one step further on.
class _SideChip extends StatelessWidget {
  const _SideChip({
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
          accent: PixiePalette.mint,
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
