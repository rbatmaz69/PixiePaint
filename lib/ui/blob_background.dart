import 'dart:math';

import 'package:flutter/material.dart';

import 'pixie_palette.dart';

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
  const BlobBackground({
    super.key,
    required this.gradient,
    required this.builder,
    this.showDoodles = true,
  });

  final Gradient gradient;

  /// Sparse ink doodles (stars, hearts, squiggles) drifting on the same
  /// wave as the blobs — the "paper" of the sticker book.
  final bool showDoodles;

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
            builder: (context, _) => CustomPaint(
              painter: _BlobPainter(_c.value),
              foregroundPainter:
                  widget.showDoodles ? _DoodlePainter(_c.value) : null,
            ),
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
  _Blob(0.15, 0.18, 0.30, PixiePalette.grapeLight, 0.00, 0.05, 0.04),
  _Blob(0.85, 0.12, 0.24, PixiePalette.skyLight, 0.35, 0.04, 0.05),
  _Blob(0.90, 0.75, 0.32, PixiePalette.bubblegumLight, 0.60, 0.05, 0.03),
  _Blob(0.10, 0.85, 0.26, PixiePalette.sunshineLight, 0.15, 0.04, 0.05),
  _Blob(0.55, 0.45, 0.20, PixiePalette.mintLight, 0.80, 0.06, 0.04),
];

enum _DoodleKind { star, heart, circle, squiggle, sparkle }

class _Doodle {
  const _Doodle(this.kind, this.x, this.y, this.size, this.phase, this.rot);
  final _DoodleKind kind;
  final double x, y; // fraction of the area
  final double size; // px
  final double phase; // 0..1
  final double rot; // base rotation, radians
}

/// Sparse hand-drawn doodles scattered like faint pen marks on the paper.
const _doodles = [
  _Doodle(_DoodleKind.star, 0.08, 0.10, 34, 0.05, 0.3),
  _Doodle(_DoodleKind.squiggle, 0.30, 0.06, 44, 0.55, -0.2),
  _Doodle(_DoodleKind.heart, 0.68, 0.09, 28, 0.30, 0.25),
  _Doodle(_DoodleKind.sparkle, 0.92, 0.22, 26, 0.75, 0.0),
  _Doodle(_DoodleKind.circle, 0.05, 0.38, 30, 0.45, 0.0),
  _Doodle(_DoodleKind.sparkle, 0.45, 0.30, 24, 0.15, 0.5),
  _Doodle(_DoodleKind.star, 0.88, 0.48, 38, 0.90, -0.35),
  _Doodle(_DoodleKind.heart, 0.16, 0.62, 32, 0.65, -0.15),
  _Doodle(_DoodleKind.squiggle, 0.60, 0.58, 48, 0.20, 0.15),
  _Doodle(_DoodleKind.circle, 0.90, 0.80, 26, 0.40, 0.0),
  _Doodle(_DoodleKind.star, 0.38, 0.86, 30, 0.10, 0.4),
  _Doodle(_DoodleKind.sparkle, 0.70, 0.90, 28, 0.85, -0.25),
];

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.t);

  final double t;

  // Unit paths (fit roughly into -0.5..0.5), built once and reused.
  static final Path _star = _makeStar();
  static final Path _heart = _makeHeart();
  static final Path _circle = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.45));
  static final Path _squiggle = _makeSquiggle();
  static final Path _sparkle = _makeSparkle();

  static Path _makeStar() {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 0.5 : 0.22;
      final a = -pi / 2 + i * pi / 5;
      final p = Offset(cos(a), sin(a)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  static Path _makeHeart() {
    return Path()
      ..moveTo(0, 0.42)
      ..cubicTo(-0.52, 0.05, -0.46, -0.42, 0, -0.18)
      ..cubicTo(0.46, -0.42, 0.52, 0.05, 0, 0.42)
      ..close();
  }

  static Path _makeSquiggle() {
    return Path()
      ..moveTo(-0.5, 0)
      ..cubicTo(-0.3, -0.3, -0.15, 0.3, 0.05, 0)
      ..cubicTo(0.25, -0.3, 0.35, 0.3, 0.5, 0);
  }

  static Path _makeSparkle() {
    return Path()
      ..moveTo(0, -0.5)
      ..lineTo(0, 0.5)
      ..moveTo(-0.5, 0)
      ..lineTo(0.5, 0);
  }

  static Path _pathFor(_DoodleKind kind) => switch (kind) {
        _DoodleKind.star => _star,
        _DoodleKind.heart => _heart,
        _DoodleKind.circle => _circle,
        _DoodleKind.squiggle => _squiggle,
        _DoodleKind.sparkle => _sparkle,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PixiePalette.ink.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final d in _doodles) {
      final angle = 2 * pi * (t + d.phase);
      final dx = (d.x + 0.015 * sin(angle)) * size.width;
      final dy = (d.y + 0.015 * cos(angle)) * size.height;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(d.rot + sin(angle) * 4 * pi / 180);
      // Unit paths are scaled by the canvas matrix, so the stroke width
      // must be divided back to stay a constant 2.5 px.
      canvas.scale(d.size);
      paint.strokeWidth = 2.5 / d.size;
      canvas.drawPath(_pathFor(d.kind), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => old.t != t;
}

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
