import 'dart:math';

import 'package:flutter/material.dart';

/// Playful loading indicator: a bouncing emoji with a little squash on
/// landing. Replaces bare [CircularProgressIndicator]s.
class LoadingPixie extends StatefulWidget {
  const LoadingPixie({super.key, this.emoji = '🖌️', this.label});

  final String emoji;
  final String? label;

  @override
  State<LoadingPixie> createState() => _LoadingPixieState();
}

class _LoadingPixieState extends State<LoadingPixie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 850))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            // Parabolic hop; squash briefly around the landing.
            final hop = sin(t * pi);
            final dy = -26.0 * hop;
            final squash = t > 0.88 || t < 0.06 ? 0.82 : 1.0;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(scaleY: squash, child: child),
            );
          },
          child: Text(widget.emoji, style: const TextStyle(fontSize: 46)),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 14),
          Text(widget.label!, style: Theme.of(context).textTheme.titleMedium),
        ],
      ],
    );
  }
}
