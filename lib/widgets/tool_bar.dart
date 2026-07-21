import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/tool.dart';
import '../ui/app_theme.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/pixie_palette.dart';
import 'fill_pattern_picker.dart';
import 'shape_picker.dart' as shapes;
import 'size_picker.dart';
import 'stamp_picker.dart';
import 'symmetry_picker.dart' as symmetry;

/// Accent color per tool — used for the selected highlight so every tool
/// feels like its own little character. Harmonized with the PixiePalette.
Color toolAccent(ToolKind tool) => switch (tool) {
  ToolKind.brush => PixiePalette.grape,
  ToolKind.marker => PixiePalette.sky,
  ToolKind.crayon => PixiePalette.tangerine,
  ToolKind.rainbow => PixiePalette.berry,
  ToolKind.glitter => PixiePalette.bubblegum,
  ToolKind.neon => const Color(0xFFFFB020),
  ToolKind.eraser => const Color(0xFF90A4AE),
  ToolKind.fill => const Color(0xFF2BB68A),
  ToolKind.stamp => const Color(0xFFFFB020),
  ToolKind.eyedropper => const Color(0xFF00A28C),
  ToolKind.shape => const Color(0xFF7C6BF0),
};

/// Emoji per tool — carries the meaning for kids who can't read yet.
String toolEmoji(
  ToolKind tool, {
  String stampEmoji = '⭐',
  String shapeEmoji = '💜',
}) => switch (tool) {
  ToolKind.brush => '🖌️',
  ToolKind.marker => '🖊️',
  ToolKind.crayon => '🖍️',
  ToolKind.rainbow => '🌈',
  ToolKind.glitter => '✨',
  ToolKind.neon => '⚡',
  ToolKind.eraser => '🧽',
  ToolKind.fill => '🪣',
  ToolKind.stamp => stampEmoji,
  ToolKind.eyedropper => '💧',
  ToolKind.shape => shapeEmoji,
};

String toolLabel(BuildContext context, ToolKind tool) => switch (tool) {
  ToolKind.brush => context.l10n.toolBrush,
  ToolKind.marker => context.l10n.toolMarker,
  ToolKind.crayon => context.l10n.toolCrayon,
  ToolKind.rainbow => context.l10n.toolRainbow,
  ToolKind.glitter => context.l10n.toolGlitter,
  ToolKind.neon => context.l10n.toolNeon,
  ToolKind.eraser => context.l10n.toolEraser,
  ToolKind.fill => context.l10n.toolFill,
  ToolKind.stamp => context.l10n.toolSticker,
  ToolKind.eyedropper => context.l10n.toolEyedropper,
  ToolKind.shape => context.l10n.toolShapes,
};

class ToolBarRail extends StatelessWidget {
  const ToolBarRail({
    super.key,
    required this.controller,
    this.showFill = true,
    this.fillOnly = false,
    this.direction = Axis.vertical,
  });

  final CanvasController controller;
  final bool showFill;

  /// Color-by-number: only the bucket (plain, no pattern picker) plus
  /// undo/redo/clear — the numbered palette does the color choosing.
  final bool fillOnly;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final children = _buildGroups(context);
        return SingleChildScrollView(
          scrollDirection: direction,
          child: direction == Axis.vertical
              ? Column(mainAxisSize: MainAxisSize.min, children: children)
              : Row(mainAxisSize: MainAxisSize.min, children: children),
        );
      },
    );
  }

  /// Rounded pill container around one group of buttons.
  Widget _group(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PixiePalette.grape.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: direction == Axis.vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: children)
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  List<Widget> _buildGroups(BuildContext context) {
    final tools = fillOnly
        ? [ToolKind.fill]
        : [
            ToolKind.brush,
            ToolKind.marker,
            ToolKind.crayon,
            ToolKind.rainbow,
            ToolKind.glitter,
            ToolKind.neon,
            ToolKind.stamp,
            ToolKind.shape,
            if (showFill) ToolKind.fill,
            ToolKind.eyedropper,
            ToolKind.eraser,
          ];
    return [
      _group(context, [
        for (final tool in tools)
          _ToolButton(
            tool: tool,
            controller: controller,
            onTap: switch (tool) {
              ToolKind.stamp => () => showStampPicker(context, controller),
              ToolKind.shape => () => shapes.showShapePicker(
                context,
                controller,
              ),
              ToolKind.fill => fillOnly
                  ? () => controller.selectTool(ToolKind.fill)
                  : () => showFillPatternPicker(context, controller),
              _ => () => controller.selectTool(tool),
            },
          ),
      ]),
      if (!fillOnly)
        _group(context, [
          _SizeButton(
            brushSize: controller.brushSize,
            color: controller.color,
            onTap: () => showSizePicker(context, controller),
          ),
          _SymmetryButton(
            controller: controller,
            onTap: () => symmetry.showSymmetryPicker(context, controller),
          ),
        ]),
      _group(context, [
        _ActionButton(
          icon: Icons.undo_rounded,
          enabled: controller.canUndo,
          filled: true,
          onTap: controller.undo,
        ),
        _ActionButton(
          icon: Icons.redo_rounded,
          enabled: controller.canRedo,
          filled: true,
          onTap: controller.redo,
        ),
        _ActionButton(
          icon: Icons.delete_sweep_outlined,
          enabled: !controller.isEmpty,
          onTap: () => _confirmClear(context),
        ),
      ]),
    ];
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showKidDialog<bool>(
      context: context,
      emoji: '🧽',
      title: context.l10n.clearTitle,
      body: Text(context.l10n.clearBody, textAlign: TextAlign.center),
      actions: [
        Builder(
          builder: (context) => KidDialogButton(
            label: context.l10n.clearKeep,
            emoji: '🖌️',
            onTap: () => Navigator.pop(context, false),
          ),
        ),
        Builder(
          builder: (context) => KidDialogTextButton(
            label: context.l10n.clearConfirm,
            onTap: () => Navigator.pop(context, true),
          ),
        ),
      ],
    );
    if (ok == true) controller.clearAll();
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tool,
    required this.controller,
    required this.onTap,
  });

  final ToolKind tool;
  final CanvasController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = controller.tool == tool;
    final accent = toolAccent(tool);
    final showColorBadge =
        tool == ToolKind.brush ||
        tool == ToolKind.fill ||
        tool == ToolKind.shape;

    // The whole toolbar speaks emoji — the same language as the pickers
    // and the tool chip. Stamp/shape show their selected motif.
    final emoji = switch (tool) {
      ToolKind.stamp =>
        controller.stampImage != null ? '🖼️' : controller.stampEmoji,
      ToolKind.shape => shapes.shapeEmoji(controller.shapeKind),
      _ => toolEmoji(tool),
    };

    return Tooltip(
      message: toolLabel(context, tool),
      child: Bouncy(
        onTap: onTap,
        playTick: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          width: 52,
          height: 52,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(selected ? 18 : 26),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Opacity(
                  opacity: selected ? 1.0 : 0.75,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              if (showColorBadge)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: controller.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Magic-mirror button: shows the active mode's motif (🦋/🌸/❄️), or a dimmed
/// butterfly when symmetry is off. Opens the symmetry picker sheet.
class _SymmetryButton extends StatelessWidget {
  const _SymmetryButton({required this.controller, required this.onTap});

  final CanvasController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = controller.symmetryFolds > 1;
    const accent = Color(0xFF7C6BF0);
    return Tooltip(
      message: context.l10n.symmetryTitle,
      child: Bouncy(
        onTap: onTap,
        playTick: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          width: 52,
          height: 52,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(active ? 18 : 26),
            border: Border.all(
              color: active ? accent : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedScale(
              scale: active ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Opacity(
                opacity: active ? 1.0 : 0.4,
                child: Text(
                  active
                      ? symmetry.symmetryEmoji(controller.symmetryFolds)
                      : '🦋',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single size button: a dot whose diameter tracks the current brush size.
/// Tapping opens the size sheet with the big slider and S/M/L presets.
class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.brushSize,
    required this.color,
    required this.onTap,
  });

  final double brushSize;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = color == const Color(0xFFFFFFFF);
    // Map the canvas-unit size onto a readable 10–30 px preview dot.
    final t = (brushSize - kMinBrushSize) / (kMaxBrushSize - kMinBrushSize);
    final previewDiameter = 10.0 + t.clamp(0.0, 1.0) * 20.0;
    return Bouncy(
      onTap: onTap,
      playTick: false,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(1),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: previewDiameter,
              height: previewDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: isWhite ? Colors.black26 : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Icon(
                Icons.unfold_more_rounded,
                size: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: filled && enabled ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: filled && enabled
              ? PixieTokens.softShadow(PixiePalette.grape)
              : null,
        ),
        child: Icon(
          icon,
          size: 26,
          color: enabled
              ? PixiePalette.ink.withValues(alpha: 0.7)
              : PixiePalette.ink.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
