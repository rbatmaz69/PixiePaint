import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../ui/bouncy.dart';
import '../util/color_utils.dart';
import 'color_picker_sheet.dart';

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

/// Height the palette row asks for. Trimmed from 76 in v8.0: on a phone in
/// portrait every dp the two bars give back goes to the paper, and the
/// swatch itself (42, 51 when selected) never needed the rest.
const double kPaletteHeight = 66;

/// Spoken name for a palette color, in the same order as [kPaletteColors].
///
/// A swatch is pure color with no text in it, so without this a screen
/// reader announces sixteen identical buttons. Colors mixed in the picker
/// sheet or lifted with the eyedropper fall back to a generic name — there
/// is no honest word for #7A3B91.
String paletteColorLabel(BuildContext context, Color color) {
  final l10n = context.l10n;
  final names = [
    l10n.colorRed,
    l10n.colorOrange,
    l10n.colorYellow,
    l10n.colorLightGreen,
    l10n.colorGreen,
    l10n.colorTurquoise,
    l10n.colorLightBlue,
    l10n.colorBlue,
    l10n.colorPurple,
    l10n.colorPink,
    l10n.colorRose,
    l10n.colorBrown,
    l10n.colorSkin,
    l10n.colorGrey,
    l10n.colorBlack,
    l10n.colorWhite,
  ];
  final i = kPaletteColors.indexOf(color);
  return i >= 0 && i < names.length ? names[i] : l10n.colorCustom;
}

class ColorPalette extends StatelessWidget {
  const ColorPalette({super.key, required this.controller});

  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final custom = !kPaletteColors.contains(controller.color);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              for (final c in kPaletteColors)
                PixieColorSwatch(
                  color: c,
                  selected: controller.color == c,
                  onTap: () => controller.selectColor(c),
                ),
              // A color picked from the big sheet or the eyedropper lives
              // here so its selection stays visible.
              if (custom)
                PixieColorSwatch(
                  color: controller.color,
                  selected: true,
                  onTap: () => showColorPickerSheet(context, controller),
                ),
              _MoreColorsSwatch(
                onTap: () => showColorPickerSheet(context, controller),
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
class PixieColorSwatch extends StatelessWidget {
  const PixieColorSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.slotWidth = 56,
    this.slotHeight = 54,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double slotWidth;
  final double slotHeight;

  @override
  Widget build(BuildContext context) {
    final light = needsBorder(color);
    return Bouncy(
      onTap: onTap,
      playTick: false,
      minSize: 0,
      semanticLabel: paletteColorLabel(context, color),
      semanticSelected: selected,
      child: SizedBox(
        width: slotWidth,
        height: slotHeight,
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
                      : (light ? Colors.black26 : Colors.transparent),
                  width: selected ? 3 : 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: (light ? Colors.black26 : color)
                              .withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? Icon(Icons.check,
                      color: light ? Colors.black54 : Colors.white, size: 24)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rainbow "+" swatch at the end of the row — opens the big color sheet.
class _MoreColorsSwatch extends StatelessWidget {
  const _MoreColorsSwatch({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      playTick: false,
      minSize: 0,
      semanticLabel: context.l10n.colorMore,
      child: SizedBox(
        width: 56,
        height: 60,
        child: Center(
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xFFE53935),
                  Color(0xFFFFC107),
                  Color(0xFF43A047),
                  Color(0xFF29B6F6),
                  Color(0xFF5E35B1),
                  Color(0xFFEC407A),
                  Color(0xFFE53935),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B6DFF).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
