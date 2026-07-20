import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../models/tool.dart';
import 'canvas_controller.dart';

/// Short sparkle "plop" where a stamp just landed. Lives INSIDE the
/// transformed canvas space (see PaintingCanvas), so it scales with zoom.
/// The stamp itself is committed into the raster layer and can't animate —
/// this is a purely additive garnish, mirroring [FillBurstOverlay].
class StampBurstOverlay extends StatefulWidget {
  const StampBurstOverlay({super.key, required this.controller});

  final CanvasController controller;

  @override
  State<StampBurstOverlay> createState() => _StampBurstOverlayState();
}

class _StampBurstOverlayState extends State<StampBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  Offset? _pos;
  double _size = 220;

  @override
  void initState() {
    super.initState();
    widget.controller.lastStamp.addListener(_onStamp);
  }

  void _onStamp() {
    final pos = widget.controller.lastStamp.value;
    if (pos == null) return;
    _pos = pos;
    _size = stampSizeFor(widget.controller.brushSize);
    _anim.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.lastStamp.removeListener(_onStamp);
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
          painter: _StampBurstPainter(pos, _anim.value, _size),
        );
      },
    );
  }
}

class _StampBurstPainter extends CustomPainter {
  _StampBurstPainter(this.center, this.t, this.stampSize);

  final Offset center;
  final double t; // 0..1
  final double stampSize;

  static const Color _gold = Color(0xFFFFE082);

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeOutCubic.transform(t);
    final opacity = (1 - t).clamp(0.0, 1.0);
    final half = stampSize / 2;

    // Ghost ring settling around the stamp.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lerpDouble(18, 3, ease)!
      ..color = Colors.white.withValues(alpha: opacity * 0.7);
    canvas.drawCircle(center, lerpDouble(half * 0.8, half * 1.2, ease)!, ring);

    // Five sparkles flying outward.
    for (var i = 0; i < 5; i++) {
      final angle = i * 2 * pi / 5 - pi / 2;
      final p = center +
          Offset(cos(angle), sin(angle)) *
              lerpDouble(half * 0.6, half * 1.35, ease)!;
      final dot = Paint()
        ..color = (i.isEven ? Colors.white : _gold)
            .withValues(alpha: opacity);
      canvas.drawCircle(p, lerpDouble(stampSize * 0.06, 3, ease)!, dot);
    }
  }

  @override
  bool shouldRepaint(_StampBurstPainter old) =>
      old.t != t || old.center != center || old.stampSize != stampSize;
}
