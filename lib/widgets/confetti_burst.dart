import 'dart:math';

import 'package:flutter/material.dart';

import 'color_palette.dart';

/// Full-screen confetti rain for ~1.2s, self-removing. No dependencies.
void showConfetti(BuildContext context) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ConfettiOverlay(onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _Particle {
  final double x; // 0..1 relative horizontal start
  final double speed; // fall speed factor
  final double drift; // horizontal sway amplitude
  final double phase;
  final double size;
  final double spin;
  final Color color;

  _Particle(Random rng)
      : x = rng.nextDouble(),
        speed = 0.7 + rng.nextDouble() * 0.6,
        drift = 20 + rng.nextDouble() * 40,
        phase = rng.nextDouble() * 2 * pi,
        size = 8 + rng.nextDouble() * 10,
        spin = (rng.nextDouble() - 0.5) * 12,
        color = kPaletteColors[rng.nextInt(kPaletteColors.length - 2)];
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  final List<_Particle> _particles =
      List.generate(44, (_) => _Particle(Random()));

  @override
  void initState() {
    super.initState();
    _anim.forward().whenCompleteOrCancel(widget.onDone);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _anim.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final fade = t > 0.75 ? (1 - t) / 0.25 : 1.0;
    for (final p in particles) {
      final y = -30 + t * p.speed * (size.height + 60);
      if (y > size.height) continue;
      final x = p.x * size.width + sin(t * 6 + p.phase) * p.drift;
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.spin + p.phase);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
