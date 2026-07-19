import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/tool.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import 'fill_pattern_picker.dart';
import 'stamp_picker.dart';

/// Accent color per tool — used for the selected highlight so every tool
/// feels like its own little character.
Color toolAccent(ToolKind tool) => switch (tool) {
      ToolKind.brush => const Color(0xFF7C4DFF),
      ToolKind.marker => const Color(0xFF29B6F6),
      ToolKind.crayon => const Color(0xFFFF8A65),
      ToolKind.rainbow => const Color(0xFFEC407A),
      ToolKind.glitter => const Color(0xFFF06292),
      ToolKind.neon => const Color(0xFFFFC107),
      ToolKind.eraser => const Color(0xFF90A4AE),
      ToolKind.fill => const Color(0xFF26A69A),
      ToolKind.stamp => const Color(0xFFFFB300),
    };

/// Emoji per tool — carries the meaning for kids who can't read yet.
String toolEmoji(ToolKind tool, {String stampEmoji = '⭐'}) => switch (tool) {
      ToolKind.brush => '🖌️',
      ToolKind.marker => '🖊️',
      ToolKind.crayon => '🖍️',
      ToolKind.rainbow => '🌈',
      ToolKind.glitter => '✨',
      ToolKind.neon => '⚡',
      ToolKind.eraser => '🧽',
      ToolKind.fill => '🪣',
      ToolKind.stamp => stampEmoji,
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
    };

class ToolBarRail extends StatelessWidget {
  const ToolBarRail({
    super.key,
    required this.controller,
    this.showFill = true,
    this.direction = Axis.vertical,
  });

  final CanvasController controller;
  final bool showFill;
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: direction == Axis.vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: children)
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  List<Widget> _buildGroups(BuildContext context) {
    final tools = [
      ToolKind.brush,
      ToolKind.marker,
      ToolKind.crayon,
      ToolKind.rainbow,
      ToolKind.glitter,
      ToolKind.neon,
      ToolKind.stamp,
      if (showFill) ToolKind.fill,
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
              ToolKind.fill => () =>
                  showFillPatternPicker(context, controller),
              _ => () => controller.selectTool(tool),
            },
          ),
      ]),
      _group(context, [
        for (var i = 0; i < kBrushSizes.length; i++)
          _SizeButton(
            previewDiameter: 10.0 + i * 9,
            color: controller.color,
            selected: controller.sizeIndex == i,
            onTap: () => controller.selectSize(i),
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
    final isStamp = tool == ToolKind.stamp;
    final showColorBadge = tool == ToolKind.brush || tool == ToolKind.fill;

    final icon = switch (tool) {
      ToolKind.brush => Icons.brush,
      ToolKind.marker => Icons.edit,
      ToolKind.crayon => Icons.gesture,
      ToolKind.rainbow => Icons.looks,
      ToolKind.glitter => Icons.auto_awesome,
      ToolKind.neon => Icons.flash_on,
      ToolKind.eraser => Icons.cleaning_services,
      ToolKind.fill => Icons.format_color_fill,
      ToolKind.stamp => null,
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
            color: selected
                ? accent.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(selected ? 18 : 26),
            border: selected
                ? Border.all(color: accent.withValues(alpha: 0.6), width: 2.5)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: isStamp
                    ? Text(controller.stampEmoji,
                        style: const TextStyle(fontSize: 24))
                    : Icon(
                        icon,
                        size: 26,
                        color: selected
                            ? accent
                            : Theme.of(context).colorScheme.onSurfaceVariant,
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

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.previewDiameter,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  /// Dot diameter — proportional to the real brush width.
  final double previewDiameter;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWhite = color == const Color(0xFFFFFFFF);
    return Bouncy(
      onTap: onTap,
      playTick: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: AnimatedScale(
          scale: selected ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Container(
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
    final scheme = Theme.of(context).colorScheme;
    return Bouncy(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: filled && enabled
              ? scheme.secondaryContainer
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 26,
          color: enabled
              ? (filled ? scheme.onSecondaryContainer : scheme.onSurfaceVariant)
              : scheme.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
