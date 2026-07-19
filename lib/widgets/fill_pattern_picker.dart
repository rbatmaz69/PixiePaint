import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../canvas/fill_pattern.dart';
import '../l10n/l10n.dart';
import '../ui/bouncy.dart';
import '../ui/kid_sheet.dart';

/// Bottom sheet with the four fill patterns; picking one selects the fill
/// tool with that pattern.
Future<void> showFillPatternPicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: '🪣',
    title: context.l10n.toolFill,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: [
          for (final (pattern, label) in [
            (FillPattern.solid, context.l10n.patternSolid),
            (FillPattern.dots, context.l10n.patternDots),
            (FillPattern.stripes, context.l10n.patternStripes),
            (FillPattern.rainbow, context.l10n.patternRainbow),
          ])
            _PatternTile(
              pattern: pattern,
              label: label,
              color: controller.color,
              selected: controller.fillPattern == pattern,
              onTap: () {
                controller.selectFillPattern(pattern);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    ),
  );
}

class _PatternTile extends StatelessWidget {
  const _PatternTile({
    required this.pattern,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final FillPattern pattern;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Bouncy(
      onTap: onTap,
      playTick: false,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? Border.all(color: scheme.primary, width: 2.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                size: const Size(84, 84),
                painter: _PatternPreviewPainter(pattern, color),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _PatternPreviewPainter extends CustomPainter {
  const _PatternPreviewPainter(this.pattern, this.color);

  final FillPattern pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final paint = Paint();
    // Sample the real pattern math in 2px blocks, scaled 3x so the pattern
    // repeat is visible inside the small tile.
    const block = 2.0, scale = 3;
    for (var y = 0; y < size.height / block; y++) {
      for (var x = 0; x < size.width / block; x++) {
        final c = patternColorAt(pattern, x * scale, y * scale, r, g, b);
        paint.color = Color(0xFF000000 | c);
        canvas.drawRect(
            Rect.fromLTWH(x * block, y * block, block, block), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPreviewPainter old) =>
      old.pattern != pattern || old.color != color;
}
