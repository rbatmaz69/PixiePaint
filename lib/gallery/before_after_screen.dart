import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../models/coloring_page.dart';
import '../photo/photo_lineart.dart';
import '../ui/motion.dart';
import '../ui/paper_sheet.dart';
import '../ui/pixie_palette.dart';
import '../ui/pixie_surfaces.dart';
import '../ui/sticker.dart';
import '../ui/wait_screen.dart';
import '../util/image_io.dart';
import '../util/sfx.dart';
import '../util/svg_raster.dart';

/// Drag the picture back to the empty page it started as.
///
/// A finished coloring page shows what a child *has*, never what they did.
/// The outline they started from is right there on disk — the paint is its
/// own layer — so the two states differ by exactly one `drawImage`, and
/// sliding between them is the whole feature.
///
/// It is not offered for a picture with no "before" worth seeing: free
/// drawing starts on blank paper, and wiping a blank page over a painting
/// is a magic trick with nothing up its sleeve.
bool hasBeforeAfter(Artwork artwork) =>
    artwork.pageId != null || artwork.hasPhoto;

class BeforeAfterScreen extends StatefulWidget {
  const BeforeAfterScreen({super.key, required this.artwork});

  final Artwork artwork;

  @override
  State<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends State<BeforeAfterScreen>
    with SingleTickerProviderStateMixin {
  ui.Image? _background;
  ui.Image? _paint;
  RasterizedLineArt? _lineArt;
  bool _ready = false;
  bool _failed = false;

  /// How much of the finished picture is showing, 0–1. The handle sits at
  /// this fraction of the paper's width.
  final ValueNotifier<double> _wipe = ValueNotifier<double>(1);

  /// Nullable field, never `late final`: this screen can be left during the
  /// disk read, and a `late final` controller that `dispose()` touches first
  /// would be *created* there, on a torn-down element tree. Rule 4.
  AnimationController? _demoController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final artwork = widget.artwork;
      final background =
          artwork.hasPhoto && await artwork.backgroundFile.exists()
              ? await pngBytesToImage(await artwork.backgroundFile.readAsBytes())
              : null;
      final paint = await artwork.paintFile.exists()
          ? await pngBytesToImage(await artwork.paintFile.readAsBytes())
          : null;
      RasterizedLineArt? lineArt;
      if (artwork.pageId != null) {
        final page = await ColoringPage.byId(artwork.pageId!);
        if (page != null) {
          lineArt = await rasterizeSvgAsset(
              page.assetPath, artwork.width, artwork.height);
        }
      } else if (artwork.hasPhotoLineArt &&
          await artwork.lineArtFile.exists()) {
        lineArt = await lineArtFromPng(await artwork.lineArtFile.readAsBytes());
      }
      if (!mounted) {
        background?.dispose();
        paint?.dispose();
        lineArt?.dispose();
        return;
      }
      setState(() {
        _background = background;
        _paint = paint;
        _lineArt = lineArt;
        _ready = true;
      });
      _playDemo();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// One sweep to the empty page and back, once, on arrival.
  ///
  /// A handle parked at the edge of a picture that already looks finished is
  /// invisible — a child would have to guess there is anything to drag. The
  /// sweep is the instruction, and it is the same thing their finger will do.
  void _playDemo() {
    if (reducedMotion(context)) {
      // Motion off: the wipe still has to be discoverable, so it simply
      // starts half open instead of moving there.
      _wipe.value = 0.5;
      return;
    }
    final c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _demoController = c;
    c.addListener(() {
      // 1 → 0.12 → 1: open the picture up, then close it again.
      final t = PixieCurves.settle.transform(c.value);
      _wipe.value =
          t < 0.5 ? 1 - (t / 0.5) * 0.88 : 0.12 + ((t - 0.5) / 0.5) * 0.88;
    });
    c.forward();
  }

  void _setWipe(double x, double width) {
    if (width <= 0) return;
    // A finger dragging past the paper edge should pin the wipe there, not
    // stop responding.
    _demoController?.stop();
    _wipe.value = (x / width).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _demoController?.dispose();
    _wipe.dispose();
    _background?.dispose();
    _paint?.dispose();
    _lineArt?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return PixieWaitScreen(
        emoji: '👀',
        title: context.l10n.beforeAfterAction,
        accent: PixiePalette.jade,
        gradient: context.surfaces.canvasBg,
        label: context.l10n.canvasLoading,
        failed: _failed,
      );
    }
    final artwork = widget.artwork;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.surfaces.canvasBg),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: PaperSheet(
                  aspectRatio: artwork.width / artwork.height,
                  padding: EdgeInsets.zero,
                  margin: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) =>
                          _setWipe(d.localPosition.dx, constraints.maxWidth),
                      onHorizontalDragStart: (d) =>
                          _setWipe(d.localPosition.dx, constraints.maxWidth),
                      onHorizontalDragUpdate: (d) =>
                          _setWipe(d.localPosition.dx, constraints.maxWidth),
                      onHorizontalDragEnd: (_) => Sfx.instance.tick(),
                      child: ValueListenableBuilder<double>(
                        valueListenable: _wipe,
                        builder: (context, wipe, _) => Semantics(
                          slider: true,
                          label: context.l10n.beforeAfterAction,
                          value: '${(wipe * 100).round()}%',
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: WipePainter(
                              background: _background,
                              paintLayer: _paint,
                              lineArt: _lineArt,
                              canvasSize: Size(artwork.width.toDouble(),
                                  artwork.height.toDouble()),
                              wipe: wipe,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: StickerCircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: context.l10n.back,
                  accent: PixiePalette.jade,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Both states of the picture, split at [wipe]: the empty page on the left,
/// the finished one on the right, and the handle where they meet.
///
/// Public so a test can paint it and look at the result — the one thing
/// that must hold is that no paint of the child's shows up on the "before"
/// side, and that is a question about pixels.
class WipePainter extends CustomPainter {
  WipePainter({
    required this.background,
    required this.paintLayer,
    required this.lineArt,
    required this.canvasSize,
    required this.wipe,
  });

  final ui.Image? background;
  final ui.Image? paintLayer;
  final RasterizedLineArt? lineArt;
  final Size canvasSize;
  final double wipe;

  @override
  void paint(Canvas canvas, Size size) {
    final split = size.width * wipe;

    canvas.save();
    // The images are canvas-sized; the paper on screen is not.
    canvas.scale(size.width / canvasSize.width, size.height / canvasSize.height);
    final full = Offset.zero & canvasSize;
    canvas.drawRect(full, Paint()..color = Colors.white);
    if (background != null) {
      canvas.drawImage(background!, Offset.zero, Paint());
    }
    if (paintLayer != null) {
      // Only the finished side gets the child's paint. Everything else is
      // identical, which is exactly what makes the difference readable.
      canvas.save();
      canvas.clipRect(
          Rect.fromLTWH(0, 0, canvasSize.width * wipe, canvasSize.height));
      canvas.drawImage(paintLayer!, Offset.zero, Paint());
      canvas.restore();
    }
    final art = lineArt;
    if (art?.picture != null) {
      canvas.drawPicture(art!.picture!);
    } else if (art != null) {
      canvas.drawImage(art.image, Offset.zero, Paint());
    }
    canvas.restore();

    _drawHandle(canvas, size, split);
  }

  /// The seam and its grab knob, in screen pixels — a handle that scaled
  /// with the picture would be a different size on every device.
  void _drawHandle(Canvas canvas, Size size, double split) {
    // Nothing to grab once the wipe is parked hard against an edge: the
    // line would read as a border of the picture.
    if (wipe <= 0.001 || wipe >= 0.999) return;
    canvas.drawLine(
        Offset(split, 0),
        Offset(split, size.height),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 5);
    canvas.drawLine(
        Offset(split, 0),
        Offset(split, size.height),
        Paint()
          ..color = PixiePalette.ink.withValues(alpha: 0.25)
          ..strokeWidth = 1.5);

    final knob = Offset(split, size.height / 2);
    canvas.drawCircle(
        knob + const Offset(0, 2),
        22,
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(knob, 22, Paint()..color = Colors.white);
    final arrow = Paint()
      ..color = PixiePalette.jade
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final dir in [-1.0, 1.0]) {
      final tip = knob + Offset(11 * dir, 0);
      canvas.drawPath(
          Path()
            ..moveTo(tip.dx - 5 * dir, tip.dy - 5)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(tip.dx - 5 * dir, tip.dy + 5),
          arrow);
    }
  }

  @override
  bool shouldRepaint(WipePainter oldDelegate) =>
      oldDelegate.wipe != wipe ||
      oldDelegate.paintLayer != paintLayer ||
      oldDelegate.background != background ||
      oldDelegate.lineArt != lineArt;
}
