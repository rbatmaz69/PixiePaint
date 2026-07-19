import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../canvas/fill_pattern.dart';
import '../l10n/l10n.dart';

/// Bottom sheet with the four fill patterns; picking one selects the fill
/// tool with that pattern (mirrors the stamp picker).
Future<void> showFillPatternPicker(
    BuildContext context, CanvasController controller) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
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
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  size: const Size(64, 64),
                  painter: _PatternPreviewPainter(pattern, color),
                ),
              ),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
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
