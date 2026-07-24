import 'package:flutter/material.dart';

import 'motion.dart';

/// One-shot entrance: scales the child from [from] to 1 with an elastic
/// overshoot and settles an optional starting rotation to zero. Fire and
/// forget — the controller runs once and the widget stays settled.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.from = 0.0,
    this.rotateFrom = 0.0,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.curve = Curves.elasticOut,
  });

  final Widget child;
  final double from;

  /// Starting rotation in radians, settles to 0.
  final double rotateFrom;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: widget.curve);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // With "reduce motion" on the entrance still happens — it just arrives
    // by fading rather than flying in and overshooting.
    if (reducedMotion(context)) {
      return FadeTransition(opacity: _c, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final t = _t.value;
        return Transform.rotate(
          angle: widget.rotateFrom * (1 - t),
          child: Transform.scale(
            scale: widget.from + (1 - widget.from) * t,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Plays a quick scale pulse (1 → [peak] → 1) whenever [trigger] changes
/// (compared via ==). Cheap: one one-shot controller, no loop.
class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.trigger,
    required this.child,
    this.peak = 1.15,
  });

  final Object? trigger;
  final Widget child;
  final double peak;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.peak)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40),
    TweenSequenceItem(
        tween: Tween(begin: widget.peak, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60),
  ]).animate(_c);

  @override
  void didUpdateWidget(Pulse old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reducedMotion(context)) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
