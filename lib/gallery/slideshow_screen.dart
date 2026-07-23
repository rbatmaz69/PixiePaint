import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../ui/loading_pixie.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/image_io.dart';
import '../util/share.dart';

/// Gallery slideshow: the tablet becomes a picture frame. Slow Ken-Burns
/// drift plus a crossfade, screen kept awake while it runs.
///
/// Memory discipline: at most two decoded images are alive at any time —
/// the one on screen and the one being prepared — and each is disposed the
/// moment it scrolls out.
class SlideshowScreen extends StatefulWidget {
  const SlideshowScreen({super.key, required this.artworks})
      : assert(artworks.length > 0, 'a slideshow needs at least one picture');

  final List<Artwork> artworks;

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen>
    with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(seconds: 7);
  static const _fadeDuration = Duration(milliseconds: 900);

  /// Render width per slide — thumbnails (360 px) look soft full screen.
  static const int _renderWidth = 1400;

  late final AnimationController _kenBurns =
      AnimationController(vsync: this, duration: _slideDuration);

  ui.Image? _current;
  ui.Image? _next;
  int _index = 0;
  int _seed = 0;
  bool _showControls = true;
  bool _disposed = false;
  Timer? _advance;
  Timer? _hideControls;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _start();
    _scheduleHideControls();
  }

  Future<void> _start() async {
    final first = await _render(widget.artworks.first);
    if (_disposed) {
      first?.dispose();
      return;
    }
    setState(() => _current = first);
    _kenBurns.forward(from: 0);
    _prepareNext();
    _advance = Timer.periodic(_slideDuration, (_) => _advanceSlide());
  }

  Future<ui.Image?> _render(Artwork artwork) async {
    try {
      final png =
          await composeSavedArtworkPng(artwork, targetWidth: _renderWidth);
      return await pngBytesToImage(png);
    } catch (_) {
      return null; // a corrupt artwork must not stop the show
    }
  }

  /// Pre-renders the following slide during the 7 s the current one shows,
  /// so the transition never stutters.
  Future<void> _prepareNext() async {
    final nextIndex = (_index + 1) % widget.artworks.length;
    final image = await _render(widget.artworks[nextIndex]);
    if (_disposed) {
      image?.dispose();
      return;
    }
    _next?.dispose();
    _next = image;
  }

  void _advanceSlide() {
    final upcoming = _next;
    if (upcoming == null) {
      // Still rendering, or the next artwork could not be decoded. Re-arm
      // the render — otherwise nothing would ever prepare a slide again and
      // the show would freeze on the current picture with the wakelock on.
      _index = (_index + 1) % widget.artworks.length;
      _prepareNext();
      return;
    }
    _next = null;
    final old = _current;
    setState(() {
      _current = upcoming;
      _index = (_index + 1) % widget.artworks.length;
      _seed++;
    });
    _kenBurns.forward(from: 0);
    // Let the crossfade finish before freeing the outgoing image.
    Timer(_fadeDuration + const Duration(milliseconds: 100),
        () => old?.dispose());
    _prepareNext();
  }

  void _scheduleHideControls() {
    _hideControls?.cancel();
    _hideControls = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onTap() {
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _disposed = true;
    _advance?.cancel();
    _hideControls?.cancel();
    _kenBurns.dispose();
    _current?.dispose();
    _next?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _current;
    return Scaffold(
      backgroundColor: PixiePalette.ink,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image == null)
              const Center(child: LoadingPixie())
            else
              AnimatedSwitcher(
                duration: _fadeDuration,
                child: KeyedSubtree(
                  key: ValueKey(_seed),
                  child: AnimatedBuilder(
                    animation: _kenBurns,
                    builder: (context, _) => CustomPaint(
                      painter: _SlidePainter(
                        image: image,
                        t: _kenBurns.value,
                        seed: _seed,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 16,
              left: 16,
              child: AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: StickerCircleButton(
                    icon: Icons.close_rounded,
                    tooltip: context.l10n.back,
                    accent: PixiePalette.grape,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws one slide contained in the viewport with a slow zoom and drift.
class _SlidePainter extends CustomPainter {
  const _SlidePainter({
    required this.image,
    required this.t,
    required this.seed,
  });

  final ui.Image image;
  final double t;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
        0, 0, image.width.toDouble(), image.height.toDouble());
    final base = containRect(
      ui.Size(image.width.toDouble(), image.height.toDouble()),
      ui.Size(size.width, size.height),
    );
    // Per-slide drift direction, deterministic so a slide always moves the
    // same way if it repeats.
    final angle = (seed * 2.39996) % (2 * pi);
    final scale = 1.0 + 0.08 * t;
    final drift = Offset(cos(angle), sin(angle)) * (12.0 * t);
    final dst = Rect.fromCenter(
      center: base.center + drift,
      width: base.width * scale,
      height: base.height * scale,
    );
    canvas.drawImageRect(
        image, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_SlidePainter old) =>
      old.image != image || old.t != t || old.seed != seed;
}
