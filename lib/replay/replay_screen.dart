import 'package:flutter/material.dart';

import '../canvas/stroke_renderer.dart';
import '../canvas/symmetry.dart';
import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../models/coloring_page.dart';
import '../models/draw_op.dart';
import '../models/tool.dart';
import '../photo/photo_lineart.dart';
import '../ui/app_theme.dart';
import '../ui/loading_pixie.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/image_io.dart';
import '../util/svg_raster.dart';
import 'replay_controller.dart';

/// Time-lapse screen: the artwork paints itself again, stroke by stroke.
class ReplayScreen extends StatefulWidget {
  const ReplayScreen({super.key, required this.artwork});

  final Artwork artwork;

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  ReplayController? controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final artwork = widget.artwork;
    final ops = decodeOps(await artwork.opsFile.readAsString());

    var background = artwork.hasPhoto && await artwork.backgroundFile.exists()
        ? await pngBytesToImage(await artwork.backgroundFile.readAsBytes())
        : null;
    RasterizedLineArt? lineArt;
    if (artwork.pageId != null) {
      final page = await ColoringPage.byId(artwork.pageId!);
      if (page != null) {
        lineArt = await rasterizeSvgAsset(
            page.assetPath, artwork.width, artwork.height);
      }
    } else if (artwork.hasPhotoLineArt && await artwork.lineArtFile.exists()) {
      lineArt = await lineArtFromPng(await artwork.lineArtFile.readAsBytes());
    }

    if (!mounted) {
      background?.dispose();
      lineArt?.dispose();
      return;
    }
    final c = ReplayController(
      width: artwork.width,
      height: artwork.height,
      ops: ops,
      background: background,
      lineArt: lineArt,
    );
    setState(() => controller = c);
    c.play();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: PixieGradients.canvasBg),
        child: SafeArea(
          child: c == null
              ? Center(child: LoadingPixie(label: context.l10n.canvasLoading))
              : Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AspectRatio(
                          // From the artwork's own size, not the current
                          // canvas constants — older or future works may
                          // have been saved at other dimensions.
                          aspectRatio: c.width / c.height,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      PixiePalette.ink.withValues(alpha: 0.12),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: c.width.toDouble(),
                                height: c.height.toDouble(),
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: _ReplayPainter(c),
                                    size: Size(c.width.toDouble(),
                                        c.height.toDouble()),
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
                        accent: PixiePalette.grape,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ListenableBuilder(
                        listenable: c,
                        builder: (context, _) => Row(
                          children: [
                            _SpeedButton(controller: c),
                            const SizedBox(width: 8),
                            // Replay again once the show is over.
                            AnimatedOpacity(
                              opacity: c.done ? 1 : 0,
                              duration: const Duration(milliseconds: 250),
                              child: IgnorePointer(
                                ignoring: !c.done,
                                child: StickerCircleButton(
                                  icon: Icons.replay_rounded,
                                  tooltip: context.l10n.replayAgain,
                                  accent: PixiePalette.mint,
                                  onTap: c.play,
                                ),
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
    );
  }
}

/// Round pill showing the current speed (1×/2×/4×); tap to cycle.
class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.controller});

  final ReplayController controller;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.replaySpeed,
      child: GestureDetector(
        onTap: controller.cycleSpeed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: PixieTokens.softShadow(PixiePalette.grape),
          ),
          child: Text(
            '${controller.speed.round()}×',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ReplayPainter extends CustomPainter {
  _ReplayPainter(this.controller) : super(repaint: controller.repaint);

  final ReplayController controller;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = Colors.white);
    final background = controller.background;
    if (background != null) {
      canvas.drawImage(background, Offset.zero, Paint());
    }
    final layer = controller.layer;
    final stroke = controller.activeStroke;
    // Same eraser trick as the live painter: saveLayer scope so a clearing
    // stroke erases the paint layer, never the paper/photo below.
    final erasing = stroke?.kind == ToolKind.eraser;
    if (erasing) canvas.saveLayer(Offset.zero & size, Paint());
    if (layer != null) canvas.drawImage(layer, Offset.zero, Paint());
    if (stroke != null) {
      final center = Offset(size.width / 2, size.height / 2);
      for (final copy in symmetryCopies(controller.activeSymmetryFolds)) {
        canvas.save();
        applySymmetryTransform(canvas, center, copy);
        StrokeRenderer.draw(canvas, stroke);
        canvas.restore();
      }
    }
    if (erasing) canvas.restore();
    final lineArt = controller.lineArt;
    if (lineArt?.picture != null) {
      canvas.drawPicture(lineArt!.picture!);
    } else if (lineArt != null) {
      canvas.drawImage(lineArt.image, Offset.zero, Paint());
    }
  }

  @override
  bool shouldRepaint(_ReplayPainter oldDelegate) =>
      oldDelegate.controller != controller;
}
