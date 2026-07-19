import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../ui/bouncy.dart';

const List<Color> kPaletteColors = [
  Color(0xFFE53935), // rot
  Color(0xFFFF7043), // orange
  Color(0xFFFFC107), // gelb
  Color(0xFF9CCC65), // hellgrün
  Color(0xFF43A047), // grün
  Color(0xFF26A69A), // türkis
  Color(0xFF29B6F6), // hellblau
  Color(0xFF1E88E5), // blau
  Color(0xFF5E35B1), // lila
  Color(0xFFEC407A), // pink
  Color(0xFFF8BBD0), // rosa
  Color(0xFF8D6E63), // braun
  Color(0xFFF1C27D), // hautton
  Color(0xFF90A4AE), // grau
  Color(0xFF000000), // schwarz
  Color(0xFFFFFFFF), // weiß
];

class ColorPalette extends StatelessWidget {
  const ColorPalette({super.key, required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              for (final c in kPaletteColors)
                _ColorSwatch(
                  color: c,
                  selected: controller.color == c,
                  onTap: () => controller.selectColor(c),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Squircle swatch in a fixed-size slot: selection only scales and decorates
/// (AnimatedScale), never changes layout — so picking a color doesn't
/// relayout the whole scroll row.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(
      {required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = color == const Color(0xFFFFFFFF);
    return Bouncy(
      onTap: onTap,
      playTick: false,
      minSize: 0,
      child: SizedBox(
        width: 56,
        height: 60,
        child: Center(
          child: AnimatedScale(
            scale: selected ? 1.22 : 1.0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(selected ? 14 : 21),
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : (isWhite ? Colors.black26 : Colors.transparent),
                  width: selected ? 3 : 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: (isWhite ? Colors.black26 : color)
                              .withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? Icon(Icons.check,
                      color: isWhite ? Colors.black54 : Colors.white, size: 24)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
