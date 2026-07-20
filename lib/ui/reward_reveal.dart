import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/confetti_burst.dart';
import 'kid_dialog.dart';
import 'pop_in.dart';

/// Full-screen sticker unlock moment: dark scrim, soft light rays, the
/// sticker springs in huge, then title/body/button slide up. Pops itself
/// when the button is tapped.
Future<void> showRewardReveal(
  BuildContext context, {
  required String emoji,
  required String title,
  required String body,
  required String buttonLabel,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'reward',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 550),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      child: child,
    ),
    pageBuilder: (context, anim, _) => _RewardRevealContent(
      route: anim,
      emoji: emoji,
      title: title,
      body: body,
      buttonLabel: buttonLabel,
    ),
  );
}

class _RewardRevealContent extends StatefulWidget {
  const _RewardRevealContent({
    required this.route,
    required this.emoji,
    required this.title,
    required this.body,
    required this.buttonLabel,
  });

  final Animation<double> route;
  final String emoji;
  final String title;
  final String body;
  final String buttonLabel;

  @override
  State<_RewardRevealContent> createState() => _RewardRevealContentState();
}

class _RewardRevealContentState extends State<_RewardRevealContent>
    with SingleTickerProviderStateMixin {
  /// Deliberately one-shot (not repeat): rays fade in, slowly turn ~40°
  /// and simply settle — the dialog is dismissed long before, and no
  /// route-observer plumbing is needed for a bounded animation.
  late final AnimationController _rays = AnimationController(
      vsync: this, duration: const Duration(seconds: 6))
    ..forward();

  @override
  void initState() {
    super.initState();
    // Confetti from inside the reveal so it renders above the scrim.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showConfetti(context);
    });
  }

  @override
  void dispose() {
    _rays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textPop = CurvedAnimation(
        parent: widget.route,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic));
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _rays,
                          builder: (context, _) => CustomPaint(
                            size: const Size(260, 260),
                            painter: _RaysPainter(_rays.value),
                          ),
                        ),
                      ),
                      PopIn(
                        from: 0.0,
                        rotateFrom: -0.35,
                        delay: const Duration(milliseconds: 80),
                        duration: const Duration(milliseconds: 700),
                        child: Text(widget.emoji,
                            style: const TextStyle(fontSize: 96)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: textPop,
                  child: SlideTransition(
                    position: Tween(
                            begin: const Offset(0, 0.25), end: Offset.zero)
                        .animate(textPop),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: KidDialogButton(
                            label: widget.buttonLabel,
                            emoji: '🎉',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Twelve soft light wedges fanning out behind the sticker; they fade in
/// during the first 10% of the timeline, then rotate slowly and settle.
class _RaysPainter extends CustomPainter {
  _RaysPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final fadeIn = (t / 0.1).clamp(0.0, 1.0);
    if (fadeIn == 0) return;
    final rotation = t * 40 * pi / 180;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    // Shader in the translated (center-relative) coordinate space.
    final paint = Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withValues(alpha: 0.35 * fadeIn),
        Colors.white.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    const wedgeHalf = 8 * pi / 180;
    for (var i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(cos(angle - wedgeHalf) * radius,
            sin(angle - wedgeHalf) * radius)
        ..arcTo(Rect.fromCircle(center: Offset.zero, radius: radius),
            angle - wedgeHalf, wedgeHalf * 2, false)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.t != t;
}
