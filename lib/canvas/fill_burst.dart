import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../ui/pixie_palette.dart';
import 'canvas_controller.dart';

/// Short expanding-ring burst at the spot where a flood fill landed — and a
/// smaller, quieter one where a fill found nothing to do.
///
/// The second case used to be pure silence: tapping the bucket on a line, or
/// twice in the same place, played no sound, ran no animation and changed
/// nothing. A child cannot tell that apart from an app that has stopped
/// working, so they tap again, harder. The answer is deliberately not the
/// celebration — it is smaller, ink-coloured and over quickly. "I heard you,
/// there is nothing here."
///
/// Lives INSIDE the transformed canvas space (see PaintingCanvas), so all
/// coordinates are canvas pixels and the effect scales with the zoom.
class FillBurstOverlay extends StatefulWidget {
  const FillBurstOverlay({super.key, required this.controller});

  final CanvasController controller;

  @override
  State<FillBurstOverlay> createState() => _FillBurstOverlayState();
}

class _FillBurstOverlayState extends State<FillBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  Offset? _pos;
  Color _color = Colors.white;
  bool _missed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.lastFill.addListener(_onFill);
    widget.controller.missedFill.addListener(_onMissed);
  }

  void _onFill() {
    final pos = widget.controller.lastFill.value;
    if (pos == null) return;
    _pos = pos;
    _color = widget.controller.color;
    _missed = false;
    _anim.forward(from: 0);
  }

  void _onMissed() {
    final pos = widget.controller.missedFill.value;
    if (pos == null) return;
    _pos = pos;
    _color = PixiePalette.ink;
    _missed = true;
    _anim.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.lastFill.removeListener(_onFill);
    widget.controller.missedFill.removeListener(_onMissed);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final pos = _pos;
        if (pos == null || !_anim.isAnimating) {
          return const SizedBox.shrink();
        }
        return CustomPaint(
          painter: _BurstPainter(pos, _anim.value, _color, missed: _missed),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.center, this.t, this.color, {this.missed = false});

  final Offset center;
  final double t; // 0..1
  final Color color;

  /// Nothing was filled. Same shape, a fifth of the size and no sparkles —
  /// an acknowledgement, not a celebration.
  final bool missed;

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeOutCubic.transform(t);
    final opacity = (1 - t).clamp(0.0, 1.0);
    final radius = lerpDouble(missed ? 20 : 40, missed ? 70 : 280, ease)!;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lerpDouble(missed ? 10 : 30, 4, ease)!
      ..color = color.withValues(alpha: opacity * (missed ? 0.5 : 0.85));
    canvas.drawCircle(center, radius, ring);
    if (missed) return;

    // A few sparkles flying outward on fixed angles.
    final dot = Paint()..color = Colors.white.withValues(alpha: opacity);
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + 0.4;
      final p = center +
          Offset(cos(angle), sin(angle)) * (radius * 1.15);
      canvas.drawCircle(p, lerpDouble(14, 4, ease)!, dot);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.center != center ||
      oldDelegate.color != color ||
      oldDelegate.missed != missed;
}
