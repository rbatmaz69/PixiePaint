import 'dart:math';

import 'package:flutter/material.dart';

import '../ui/motion.dart';
import '../ui/pixie_palette.dart';
import 'canvas_controller.dart';

/// How long the hint stays before it clears itself. Long enough to look
/// from one mark to the next on a full picture, short enough that a child
/// who has already started painting again is not being pointed at.
const Duration kHintDwell = Duration(seconds: 3);

/// At most this many marks at once. A busy page can have thirty bare areas,
/// and thirty sparkles is not a hint, it is a fault report.
const int kMaxHints = 8;

/// Marks the enclosed areas that still have no paint in them.
///
/// Answers the ✨ button. The positions come from `regionCoverage`, ordered
/// biggest first, so capping at [kMaxHints] keeps the ones a child will
/// actually see.
///
/// Lives INSIDE the transformed canvas space (see PaintingCanvas), so the
/// coordinates are canvas pixels and the marks sit on their areas at any
/// zoom.
///
/// **It never paints on the picture.** The marks are an overlay that clears
/// itself after [kHintDwell]; nothing here reaches the paint layer, the op
/// log or the undo stack. Being shown where a gap is must not cost a child
/// an undo.
class AlmostDoneOverlay extends StatefulWidget {
  const AlmostDoneOverlay({super.key, required this.controller});

  final CanvasController controller;

  @override
  State<AlmostDoneOverlay> createState() => _AlmostDoneOverlayState();
}

class _AlmostDoneOverlayState extends State<AlmostDoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: kHintDwell,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.hintSpots.addListener(_onSpots);
  }

  void _onSpots() {
    if (widget.controller.hintSpots.value.isEmpty) {
      _anim.stop();
      if (mounted) setState(() {});
      return;
    }
    _anim.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.hintSpots.removeListener(_onSpots);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce motion keeps the *information* and drops the movement: the same
    // marks, standing still at full strength for the same three seconds.
    // Taking the hint away from a child who asked for it would be the wrong
    // half to remove.
    final still = reducedMotion(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final spots = widget.controller.hintSpots.value;
        if (spots.isEmpty || !_anim.isAnimating) {
          return const SizedBox.shrink();
        }
        return CustomPaint(
          painter: _HintPainter(
            spots.take(kMaxHints).toList(),
            _anim.value,
            still: still,
          ),
        );
      },
    );
  }
}

class _HintPainter extends CustomPainter {
  _HintPainter(this.spots, this.t, {required this.still});

  final List<Offset> spots;

  /// 0..1 over [kHintDwell].
  final double t;

  final bool still;

  /// Canvas pixels. The picture is 2048 across, so a mark this size is about
  /// a fingertip on the paper.
  static const double _radius = 54;

  @override
  void paint(Canvas canvas, Size size) {
    // Fade in quickly, hold, fade out over the last fifth — so the marks
    // never blink out mid-glance.
    final fade = still
        ? (t < 0.85 ? 1.0 : (1 - t) / 0.15)
        : (t < 0.1 ? t / 0.1 : (t < 0.8 ? 1.0 : (1 - t) / 0.2));
    final opacity = fade.clamp(0.0, 1.0);

    for (var i = 0; i < spots.length; i++) {
      // Each mark breathes on its own offset phase, so a row of them reads
      // as scattered sparkle rather than as one blinking machine.
      final phase = still ? 0.0 : sin((t * 3 + i * 0.35) * pi * 2);
      final scale = 1 + phase * 0.12;
      _paintStar(canvas, spots[i], _radius * scale, opacity);
    }
  }

  void _paintStar(Canvas canvas, Offset c, double r, double opacity) {
    final glow = Paint()
      ..color = PixiePalette.sunshine.withValues(alpha: opacity * 0.35);
    canvas.drawCircle(c, r, glow);

    final star = Path();
    // Four-pointed sparkle: long points on the axes, pulled in at 45°.
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 - pi / 2;
      final rr = i.isEven ? r * 0.92 : r * 0.28;
      final p = c + Offset(cos(a), sin(a)) * rr;
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()..color = Colors.white.withValues(alpha: opacity * 0.95),
    );
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = PixiePalette.grape.withValues(alpha: opacity * 0.7),
    );
  }

  @override
  bool shouldRepaint(_HintPainter old) =>
      old.t != t || old.spots != spots || old.still != still;
}
