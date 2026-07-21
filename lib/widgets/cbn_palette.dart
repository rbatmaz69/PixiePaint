import 'package:flutter/material.dart';

import '../models/cbn_spec.dart';
import '../ui/bouncy.dart';

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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
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
        scale: hinted ? 1.25 : (selected ? 1.1 : 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
                color: color.withValues(alpha: selected ? 0.6 : 0.3),
                blurRadius: selected ? 12 : 6,
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
