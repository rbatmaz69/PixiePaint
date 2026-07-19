import 'dart:math';

import 'package:flutter/material.dart';

/// Route observer so the blob animation pauses whenever any route (screen,
/// dialog or sheet) is pushed on top. Registered in [PixiePaintApp].
final RouteObserver<ModalRoute<dynamic>> pixieRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();

/// Slowly drifting pastel blobs behind the content — the "alive" home
/// backdrop. Deliberately cheap: one 28-s looping controller, ≤6 blobs
/// drawn with radial-gradient shaders (no ImageFilter blur), and a
/// [RepaintBoundary] on both the painter and the foreground so blob ticks
/// never repaint the content. Pauses when the app is backgrounded or
/// another route covers this one.
class BlobBackground extends StatefulWidget {
  const BlobBackground(
      {super.key, required this.gradient, required this.builder});

  final Gradient gradient;

  /// Builds the foreground; [wave] loops 0→1 over ~28 s and can drive
  /// slow secondary motion (e.g. the header sway) without a second ticker.
  final Widget Function(BuildContext context, Animation<double> wave) builder;

  @override
  State<BlobBackground> createState() => _BlobBackgroundState();
}

class _BlobBackgroundState extends State<BlobBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 28))
    ..repeat();

  bool _coveredByRoute = false;
  bool _appPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) pixieRouteObserver.subscribe(this, route);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appPaused = state != AppLifecycleState.resumed;
    _sync();
  }

  @override
  void didPushNext() {
    _coveredByRoute = true;
    _sync();
  }

  @override
  void didPopNext() {
    _coveredByRoute = false;
    _sync();
  }

  void _sync() {
    final shouldRun = !_coveredByRoute && !_appPaused;
    if (shouldRun && !_c.isAnimating) {
      _c.repeat();
    } else if (!shouldRun && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    pixieRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: widget.gradient)),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) =>
                CustomPaint(painter: _BlobPainter(_c.value)),
          ),
        ),
        RepaintBoundary(child: widget.builder(context, _c)),
      ],
    );
  }
}

class _Blob {
  const _Blob(this.x, this.y, this.r, this.color, this.phase, this.dx, this.dy);
  final double x, y; // base position, fraction of size
  final double r; // radius, fraction of shortest side
  final Color color;
  final double phase; // 0..1
  final double dx, dy; // drift amplitude, fraction of size
}

const _blobs = [
  _Blob(0.15, 0.18, 0.30, Color(0xFFB39DDB), 0.00, 0.05, 0.04),
  _Blob(0.85, 0.12, 0.24, Color(0xFF81D4FA), 0.35, 0.04, 0.05),
  _Blob(0.90, 0.75, 0.32, Color(0xFFF48FB1), 0.60, 0.05, 0.03),
  _Blob(0.10, 0.85, 0.26, Color(0xFFFFE082), 0.15, 0.04, 0.05),
  _Blob(0.55, 0.45, 0.20, Color(0xFFA5D6A7), 0.80, 0.06, 0.04),
];

class _BlobPainter extends CustomPainter {
  const _BlobPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    for (final b in _blobs) {
      final angle = 2 * pi * (t + b.phase);
      final cx = (b.x + b.dx * sin(angle)) * size.width;
      final cy = (b.y + b.dy * cos(angle)) * size.height;
      final r = b.r * shortest;
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [b.color.withValues(alpha: 0.4), b.color.withValues(alpha: 0)],
        ).createShader(rect);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
