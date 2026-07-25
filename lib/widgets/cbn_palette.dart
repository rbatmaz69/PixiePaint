import 'package:flutter/material.dart';

import '../models/cbn_spec.dart';
import '../ui/bouncy.dart';
import '../ui/motion.dart';
import '../ui/selection_cradle.dart';

/// Color-by-number palette: one numbered swatch per color. Solved numbers
/// get a check badge; [hintNumber] pulses to point at the right swatch
/// after repeated wrong taps.
class CbnPalette extends StatelessWidget {
  const CbnPalette({
    super.key,
    required this.spec,
    required this.selectedNumber,
    required this.doneNumbers,
    required this.hintNumber,
    required this.onSelect,
  });

  final CbnSpec spec;
  final int? selectedNumber;
  final Set<int> doneNumbers;
  final int? hintNumber;
  final ValueChanged<int> onSelect;

  /// One swatch plus the padding around it. Uniform, which is what lets
  /// [SelectionCradle] find its slot by arithmetic.
  static const double _slot = 64;

  @override
  Widget build(BuildContext context) {
    final picked = selectedNumber == null
        ? null
        : spec.numbers.indexOf(selectedNumber!);
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          children: [
            // The same dish as the paint palette. The two sit in the same
            // place on screen — a child painting a number picture and one
            // painting a normal one should not meet two different ideas of
            // what "picked" looks like.
            SelectionCradle(
              slot: picked != null && picked >= 0 ? picked : null,
              accent: selectedNumber == null
                  ? Colors.white
                  : spec.colorOf[selectedNumber!]!,
              slotWidth: _slot,
              size: 60,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final n in spec.numbers)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _Swatch(
                      number: n,
                      color: spec.colorOf[n]!,
                      selected: n == selectedNumber,
                      done: doneNumbers.contains(n),
                      hinted: n == hintNumber,
                      onTap: () => onSelect(n),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.number,
    required this.color,
    required this.selected,
    required this.done,
    required this.hinted,
    required this.onTap,
  });

  final int number;
  final Color color;
  final bool selected;
  final bool done;
  final bool hinted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: AnimatedScale(
        scale: hinted ? 1.25 : 1.0,
        duration: PixieMotion.select,
        curve: PixieCurves.spring,
        child: AnimatedContainer(
          duration: PixieMotion.select,
          curve: PixieCurves.settle,
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected || hinted ? Colors.white : Colors.white70,
              width: selected || hinted ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$number',
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 4),
                  ],
                ),
              ),
              if (done)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Text('✅', style: TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
