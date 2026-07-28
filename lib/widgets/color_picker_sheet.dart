import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../ui/bouncy.dart';
import '../ui/kid_sheet.dart';
import '../ui/motion.dart';
import '../ui/pixie_palette.dart';
import '../ui/pop_in.dart';
import '../util/color_utils.dart';
import '../util/settings.dart';
import 'color_palette.dart';

/// Bottom sheet with the big kid color grid plus a most-recently-used row
/// and the mixing pot.
/// Picking a color selects it and closes the sheet.
Future<void> showColorPickerSheet(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: '🎨',
    title: context.l10n.colorPickerTitle,
    builder: (_) => _ColorPickerBody(controller: controller),
  );
}

class _ColorPickerBody extends StatefulWidget {
  const _ColorPickerBody({required this.controller});

  final CanvasController controller;

  @override
  State<_ColorPickerBody> createState() => _ColorPickerBodyState();
}

class _ColorPickerBodyState extends State<_ColorPickerBody> {
  Color? _a;
  Color? _b;

  /// Which pot slot the next tap on a swatch goes into: 1, 2, or 0 for
  /// "none — a tap picks the colour and closes, the way it always has".
  ///
  /// The sheet's first job is still to hand over a colour, so mixing is
  /// something a child steps *into* by tapping an empty slot. Nothing about
  /// the old flow changes until they do.
  int _filling = 0;

  void _pick(Color c) {
    widget.controller.selectColor(c);
    Settings.instance.registerRecentColor(c);
    Navigator.of(context).pop();
  }

  /// A tap on any swatch in the sheet.
  void _tapSwatch(Color c) {
    if (_filling == 0) {
      _pick(c);
      return;
    }
    setState(() {
      if (_filling == 1) {
        _a = c;
        // Straight on to the other slot while the child is still in the
        // middle of the idea — two taps, one thought.
        _filling = _b == null ? 2 : 0;
      } else {
        _b = c;
        _filling = _a == null ? 1 : 0;
      }
    });
  }

  void _arm(int slot) => setState(() => _filling = _filling == slot ? 0 : slot);

  void _clear() => setState(() {
        _a = null;
        _b = null;
        _filling = 0;
      });

  @override
  Widget build(BuildContext context) {
    final recents = Settings.instance.recentColors
        .map((v) => Color(v))
        .toList(growable: false);
    final grid = kidColorGrid();
    final names = paletteColorNames(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot =
            ((constraints.maxWidth - 32) / kGridHues.length).clamp(36.0, 60.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MixingPot(
                a: _a,
                b: _b,
                filling: _filling,
                onArm: _arm,
                onClear: _clear,
                onTake: _pick,
              ),
              const SizedBox(height: PixieTokens.gapSmall),
              if (recents.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('🕐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: PixieTokens.gapSmall),
                    Text(context.l10n.colorRecent,
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final c in recents)
                        PixieColorSwatch(
                          color: c,
                          selected: widget.controller.color == c,
                          onTap: () => _tapSwatch(c),
                          slotWidth: slot,
                          slotHeight: 54,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: PixieTokens.gapSmall),
              ],
              // The grid is generated, so every swatch here knows what it
              // was built from and is named after that column rather than
              // after a guess. The last row is the neutrals, which have
              // their own list of names.
              for (var r = 0; r < grid.length; r++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < grid[r].length; i++)
                      PixieColorSwatch(
                        color: grid[r][i],
                        selected: widget.controller.color == grid[r][i],
                        onTap: () => _tapSwatch(grid[r][i]),
                        slotWidth: slot,
                        slotHeight: 50,
                        label: names[r == grid.length - 1
                            ? kGridNeutralNames[i]
                            : kGridHueNames[i]],
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

/// Two colours in, one out: 🎨 [a] + [b] → the mix, with a button to take it.
///
/// The grid hands out forty-eight fixed colours and the eyedropper lifts
/// what is already on the paper. Neither makes a colour that is not there
/// yet — and "blue and yellow make green" is a thing a child can check
/// against their own paint box, which is worth more than another row of
/// swatches. See [mixPaint] for why the mixing does not happen in RGB.
class _MixingPot extends StatelessWidget {
  const _MixingPot({
    required this.a,
    required this.b,
    required this.filling,
    required this.onArm,
    required this.onClear,
    required this.onTake,
  });

  final Color? a;
  final Color? b;
  final int filling;
  final void Function(int slot) onArm;
  final VoidCallback onClear;
  final void Function(Color c) onTake;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mixed = a != null && b != null ? mixPaint(a!, b!) : null;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: PixieTokens.gap, vertical: PixieTokens.gapSmall),
      decoration: BoxDecoration(
        color: PixiePalette.paperDeep,
        borderRadius: BorderRadius.circular(PixieTokens.rTile),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('🧪', style: TextStyle(fontSize: 18)),
              const SizedBox(width: PixieTokens.gapSmall),
              Expanded(
                child: Text(
                  filling == 0 ? l10n.colorMixTitle : l10n.colorMixHint,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (a != null || b != null)
                Bouncy(
                  onTap: onClear,
                  semanticLabel: l10n.colorMixClear,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text('🧹', style: TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: PixieTokens.gapSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Slot(
                color: a,
                waiting: filling == 1,
                label: l10n.colorMixSlot,
                onTap: () => onArm(1),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('+', style: TextStyle(fontSize: 20)),
              ),
              _Slot(
                color: b,
                waiting: filling == 2,
                label: l10n.colorMixSlot,
                onTap: () => onArm(2),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('=', style: TextStyle(fontSize: 20)),
              ),
              // The answer, and the way to keep it. Absent until there is
              // one — an empty third bowl would look like a third thing to
              // fill in.
              if (mixed != null)
                PopIn(
                  child: Bouncy(
                    onTap: () => onTake(mixed),
                    semanticLabel:
                        '${l10n.colorMixTake}, ${paletteColorLabel(context, mixed)}',
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: mixed,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: needsBorder(mixed)
                              ? PixiePalette.paperEdge
                              : Colors.transparent,
                          width: PixieTokens.strokeHair,
                        ),
                        boxShadow: PixieTokens.softShadow(PixiePalette.ink),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 54, height: 54),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the two bowls. Empty it is a dashed ring that says "tap me";
/// waiting for a colour it pulses, which is the only instruction a child
/// who cannot read gets, so it has to be the obvious thing on the sheet.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.color,
    required this.waiting,
    required this.label,
    required this.onTap,
  });

  final Color? color;
  final bool waiting;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Bouncy(
      onTap: onTap,
      semanticLabel:
          c == null ? label : paletteColorLabel(context, c),
      semanticSelected: waiting,
      child: Pulse(
        trigger: waiting,
        only: true,
        child: AnimatedContainer(
          duration: PixieMotion.select,
          curve: PixieCurves.settle,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: c ?? Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: waiting ? PixiePalette.grape : PixiePalette.paperEdge,
              width: waiting
                  ? PixieTokens.strokeSelect
                  : PixieTokens.strokeEdge,
            ),
          ),
          child: c == null
              ? const Center(
                  child: Text('?', style: TextStyle(fontSize: 20)))
              : null,
        ),
      ),
    );
  }
}
