import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../models/tool.dart';
import 'fill_pattern_picker.dart';
import 'stamp_picker.dart';

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

  Widget get _divider => direction == Axis.vertical
      ? const Divider(height: 10, indent: 12, endIndent: 12)
      : const VerticalDivider(width: 10, indent: 12, endIndent: 12);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final children = _buildButtons(context);
        return SingleChildScrollView(
          scrollDirection: direction,
          child: direction == Axis.vertical
              ? Column(mainAxisSize: MainAxisSize.min, children: children)
              : Row(mainAxisSize: MainAxisSize.min, children: children),
        );
      },
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    return [
      _ToolButton(
                icon: Icons.brush,
                label: 'Pinsel',
                selected: controller.tool == ToolKind.brush,
                onTap: () => controller.selectTool(ToolKind.brush),
              ),
              _ToolButton(
                icon: Icons.edit,
                label: 'Filzstift',
                selected: controller.tool == ToolKind.marker,
                onTap: () => controller.selectTool(ToolKind.marker),
              ),
              _ToolButton(
                icon: Icons.gesture,
                label: 'Buntstift',
                selected: controller.tool == ToolKind.crayon,
                onTap: () => controller.selectTool(ToolKind.crayon),
              ),
              _ToolButton(
                icon: Icons.looks,
                label: 'Regenbogen',
                selected: controller.tool == ToolKind.rainbow,
                onTap: () => controller.selectTool(ToolKind.rainbow),
              ),
              _ToolButton(
                icon: Icons.auto_awesome,
                label: 'Glitzer',
                selected: controller.tool == ToolKind.glitter,
                onTap: () => controller.selectTool(ToolKind.glitter),
              ),
              _ToolButton(
                icon: Icons.flash_on,
                label: 'Neon',
                selected: controller.tool == ToolKind.neon,
                onTap: () => controller.selectTool(ToolKind.neon),
              ),
              _ToolButton(
                label: 'Sticker',
                emoji: controller.stampEmoji,
                selected: controller.tool == ToolKind.stamp,
                onTap: () => showStampPicker(context, controller),
              ),
              if (showFill)
                _ToolButton(
                  icon: Icons.format_color_fill,
                  label: 'Füllen',
                  selected: controller.tool == ToolKind.fill,
                  onTap: () => showFillPatternPicker(context, controller),
                ),
              _ToolButton(
                icon: Icons.cleaning_services,
                label: 'Radierer',
                selected: controller.tool == ToolKind.eraser,
                onTap: () => controller.selectTool(ToolKind.eraser),
              ),
              _divider,
              for (var i = 0; i < kBrushSizes.length; i++)
                _SizeButton(
                  diameter: 12.0 + i * 8,
                  selected: controller.sizeIndex == i,
                  onTap: () => controller.selectSize(i),
                ),
              _divider,
              _ActionButton(
                icon: Icons.undo,
                enabled: controller.canUndo,
                onTap: controller.undo,
              ),
              _ActionButton(
                icon: Icons.redo,
                enabled: controller.canRedo,
                onTap: controller.redo,
              ),
              _ActionButton(
                icon: Icons.delete_sweep_outlined,
                enabled: !controller.isEmpty,
                onTap: () => _confirmClear(context),
              ),
    ];
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alles wegwischen?'),
        content: const Text('Möchtest du noch einmal von vorne anfangen?'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Weitermalen!'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Von vorne'),
          ),
        ],
      ),
    );
    if (ok == true) controller.clearAll();
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    this.icon,
    this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : assert(icon != null || emoji != null);

  final IconData? icon;
  final String? emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
      child: Tooltip(
        message: label,
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 54,
              height: 54,
              child: emoji != null
                  ? Center(
                      child: Text(emoji!,
                          style:
                              TextStyle(fontSize: selected ? 30 : 24)),
                    )
                  : Icon(
                      icon,
                      size: selected ? 34 : 28,
                      color:
                          selected ? scheme.primary : scheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  const _SizeButton(
      {required this.diameter, required this.selected, required this.onTap});

  final double diameter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 44,
        alignment: Alignment.center,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            border: selected
                ? Border.all(color: scheme.primaryContainer, width: 3)
                : null,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 28,
      padding: const EdgeInsets.all(8),
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
    );
  }
}
