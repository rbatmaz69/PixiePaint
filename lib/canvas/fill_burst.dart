import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'canvas_controller.dart';

/// Short expanding-ring burst at the spot where a flood fill landed.
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

  @override
  void initState() {
    super.initState();
    widget.controller.lastFill.addListener(_onFill);
  }

  void _onFill() {
    final pos = widget.controller.lastFill.value;
    if (pos == null) return;
    _pos = pos;
    _color = widget.controller.color;
    _anim.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.lastFill.removeListener(_onFill);
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
          painter: _BurstPainter(pos, _anim.value, _color),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.center, this.t, this.color);

  final Offset center;
  final double t; // 0..1
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeOutCubic.transform(t);
    final opacity = (1 - t).clamp(0.0, 1.0);
    final radius = lerpDouble(40, 280, ease)!;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lerpDouble(30, 4, ease)!
      ..color = color.withValues(alpha: opacity * 0.85);
    canvas.drawCircle(center, radius, ring);

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
      oldDelegate.color != color;
}
