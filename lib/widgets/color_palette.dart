import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../ui/bouncy.dart';
import '../ui/motion.dart';
import '../ui/pixie_palette.dart';
import '../ui/selection_cradle.dart';
import '../util/color_utils.dart';
import 'color_picker_sheet.dart';

/// Width of one swatch slot. Fixed, and that is what lets the selection
/// cradle find its target by arithmetic instead of by measuring.
const double kSwatchSlot = 56;

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
        // A custom color gets its own swatch right after the sixteen, so
        // that is where the cradle has to be for it.
        final selectedSlot = custom
            ? kPaletteColors.length
            : kPaletteColors.indexOf(controller.color);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Stack(
            children: [
              // Painted first, so it sits *behind* the swatches. It is
              // positioned, so the Row below is what sizes this Stack.
              SelectionCradle(
                slot: selectedSlot,
                accent: cradleAccent(controller.color),
                slotWidth: kSwatchSlot,
                size: 50,
              ),
              Row(
                children: [
                  for (final c in kPaletteColors)
                    PixieColorSwatch(
                      color: c,
                      selected: controller.color == c,
                      cradled: true,
                      onTap: () => controller.selectColor(c),
                    ),
                  // A color picked from the big sheet or the eyedropper lives
                  // here so its selection stays visible.
                  if (custom)
                    PixieColorSwatch(
                      color: controller.color,
                      selected: true,
                      cradled: true,
                      onTap: () => showColorPickerSheet(context, controller),
                    ),
                  _MoreColorsSwatch(
                    onTap: () => showColorPickerSheet(context, controller),
                  ),
                ],
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
    this.slotWidth = kSwatchSlot,
    this.slotHeight = 54,
    this.cradled = false,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double slotWidth;
  final double slotHeight;

  /// A [SelectionCradle] slides behind this row and carries the selection.
  ///
  /// The swatch then stops growing and stops casting its own shadow — two
  /// things saying "picked" on top of each other is louder, not clearer,
  /// and at 1.18 the swatch would grow to exactly the cradle's size and
  /// hide it completely. The picker sheet has no cradle (it is a grid, and
  /// a dish gliding across two dimensions is a different animal), so there
  /// this stays false and the swatch keeps announcing itself.
  final bool cradled;

  @override
  Widget build(BuildContext context) {
    final light = needsBorder(color);
    final bool self = selected && !cradled;
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
            scale: self ? PixieMotion.selectedScale : 1.0,
            duration: PixieMotion.select,
            curve: PixieCurves.spring,
            child: AnimatedContainer(
              duration: PixieMotion.select,
              curve: PixieCurves.settle,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                // The squircle squares off when picked — the one bit of the
                // selection the swatch keeps either way, because it is the
                // shape change a child sees under their own finger.
                borderRadius: BorderRadius.circular(selected ? 14 : 21),
                border: Border.all(
                  color: self
                      ? Colors.white
                      : (light ? Colors.black26 : Colors.transparent),
                  width: self ? 3 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (light ? Colors.black26 : color)
                        .withValues(alpha: self ? 0.45 : 0.0),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
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

  /// Six of the sixteen, evenly around the wheel. Indices rather than the
  /// values again: this circle is a promise about what is behind the "+",
  /// and a promise that copies its subject can stop being true.
  static const List<int> _wheel = [0, 2, 4, 6, 8, 9];

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
              gradient: SweepGradient(
                colors: [
                  for (final i in _wheel) kPaletteColors[i],
                  // Closes the circle where it began.
                  kPaletteColors[_wheel.first],
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: PixiePalette.grape.withValues(alpha: 0.3),
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
