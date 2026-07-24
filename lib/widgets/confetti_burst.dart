import 'dart:math';

import 'package:flutter/material.dart';

import '../ui/motion.dart';
import 'color_palette.dart';

/// How big a moment this is.
///
/// Every celebration in the app used to fire the same forty-four pieces for
/// the same 1.4 seconds, so sharing a picture felt exactly as big as
/// finishing one. It isn't.
enum ConfettiScale {
  /// A nod: something worked. Sharing, accepting the day's task.
  small(count: 18, duration: Duration(milliseconds: 900)),

  /// A real event: a picture finished, a sticker unlocked.
  party(count: 56, duration: Duration(milliseconds: 1600));

  const ConfettiScale({required this.count, required this.duration});

  final int count;
  final Duration duration;
}

/// Full-screen confetti rain, self-removing. No dependencies.
void showConfetti(BuildContext context,
    {ConfettiScale scale = ConfettiScale.party}) {
  // Paper falling across the whole screen is exactly what "reduce motion"
  // is asking us not to do. The moment itself is not cancelled: the sound,
  // the vibration and the sticker reveal all stay.
  if (reducedMotion(context)) return;
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ConfettiOverlay(scale: scale, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

/// What one piece of paper is cut into. Mixed shapes read as a handful of
/// party confetti; forty-four identical rectangles read as a texture.
enum _Shape { rect, circle, star }

class _Particle {
  final double x; // 0..1 relative horizontal start
  final double speed; // fall speed factor
  final double drift; // horizontal sway amplitude
  final double phase;
  final double size;
  final double spin;

  /// How fast the piece turns edge-on while falling — the flutter.
  final double flutter;
  final Color color;
  final _Shape shape;

  _Particle(Random rng)
      : x = rng.nextDouble(),
        speed = 0.7 + rng.nextDouble() * 0.6,
        drift = 20 + rng.nextDouble() * 40,
        phase = rng.nextDouble() * 2 * pi,
        size = 8 + rng.nextDouble() * 10,
        spin = (rng.nextDouble() - 0.5) * 12,
        flutter = 4 + rng.nextDouble() * 6,
        // Mostly rectangles, with circles and stars sprinkled through.
        shape = switch (rng.nextInt(6)) {
          0 => _Shape.star,
          1 || 2 => _Shape.circle,
          _ => _Shape.rect,
        },
        color = kPaletteColors[rng.nextInt(kPaletteColors.length - 2)];
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({required this.scale, required this.onDone});

  final ConfettiScale scale;
  final VoidCallback onDone;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: widget.scale.duration);
  late final List<_Particle> _particles =
      List.generate(widget.scale.count, (_) => _Particle(Random()));

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

  /// A five-pointed star in unit space, built once.
  static final Path _star = () {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 0.5 : 0.22;
      final a = -pi / 2 + i * pi / 5;
      final p = Offset(cos(a), sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }();

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
      // Squeezing the width on a second, faster cycle turns the flat spin
      // into paper flipping edge-on as it falls. Never fully zero — a piece
      // that vanishes for a frame reads as a flicker, not as a turn.
      canvas.scale(0.25 + 0.75 * cos(t * p.flutter + p.phase).abs(), 1.0);
      switch (p.shape) {
        case _Shape.rect:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero, width: p.size, height: p.size * 0.6),
              const Radius.circular(2),
            ),
            paint,
          );
        case _Shape.circle:
          canvas.drawCircle(Offset.zero, p.size * 0.32, paint);
        case _Shape.star:
          canvas.save();
          canvas.scale(p.size * 1.3);
          canvas.drawPath(_star, paint);
          canvas.restore();
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
