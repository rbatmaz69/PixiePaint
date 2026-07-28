import 'dart:async';
import 'package:flutter/material.dart';

import '../ui/pixie_surfaces.dart';

import '../canvas/mask_path.dart';
import '../canvas/stroke_renderer.dart';
import '../canvas/symmetry.dart';
import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../models/coloring_page.dart';
import '../models/draw_op.dart';
import '../models/tool.dart';
import '../photo/photo_lineart.dart';
import '../ui/app_theme.dart';
import '../ui/bouncy.dart';
import '../ui/wait_screen.dart';
import '../ui/motion.dart';
import '../ui/paper_sheet.dart';
import '../ui/pixie_palette.dart';
import '../ui/pop_in.dart';
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

  /// The story could not be read — a truncated op log, a missing file.
  /// Without this the screen waited for a controller that was never coming,
  /// and the back button lived in the *loaded* branch, so there was nothing
  /// to tap at all.
  bool _failed = false;

  Future<void> _load() async {
    try {
      await _loadStory();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _loadStory() async {
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
    unawaited(c.play());
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) {
      return PixieWaitScreen(
        emoji: '🎬',
        title: context.l10n.replayAction,
        accent: PixiePalette.grape,
        gradient: context.surfaces.canvasBg,
        label: context.l10n.canvasLoading,
        failed: _failed,
      );
    }
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.surfaces.canvasBg),
        child: SafeArea(
          child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: PaperSheet(
                            aspectRatio: c.width / c.height,
                            padding: EdgeInsets.zero,
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                        const SizedBox(height: PixieTokens.gapMedium),
                        _ReplayProgress(controller: c),
                        const SizedBox(height: PixieTokens.gapSmall),
                      ],
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
                            const SizedBox(width: PixieTokens.gapSmall),
                            // Replay again once the show is over.
                            AnimatedOpacity(
                              opacity: c.done ? 1 : 0,
                              duration: PixieMotion.select,
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
///
/// A [Bouncy] like every other control in the app: it was the last raw
/// [GestureDetector] left, which meant no press feedback, no tick, and —
/// worse — nothing for a screen reader to find.
class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.controller});

  final ReplayController controller;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.replaySpeed,
      excludeFromSemantics: true,
      child: Bouncy(
        onTap: controller.cycleSpeed,
        semanticLabel: context.l10n.replaySpeed,
        child: StickerPill(
          padding: const EdgeInsets.symmetric(
              horizontal: PixieTokens.gap, vertical: PixieTokens.gapSmall),
          // The number changes under the finger; without the pulse the tap
          // reads as "1× became 2×" rather than as an answer.
          child: Pulse(
            trigger: controller.speed,
            child: Text(
              '${controller.speed.round()}×',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

/// A slim crayon line under the paper, filling as the picture paints
/// itself. Without it a time-lapse of a hundred strokes gives a child no
/// idea whether it is nearly over — and the only way out looked like the
/// back button.
class _ReplayProgress extends StatelessWidget {
  const _ReplayProgress({required this.controller});

  final ReplayController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: PixiePalette.ink.withValues(alpha: 0.08),
                  ),
                  // A fraction of the available width, so this needs no
                  // measuring and no second painter.
                  FractionallySizedBox(
                    widthFactor: controller.progress.clamp(0.0, 1.0),
                    child: AnimatedContainer(
                      duration: PixieMotion.snap,
                      curve: PixieCurves.settle,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: PixieGradients.trace,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      final mask = controller.activeMask;
      if (mask != null) {
        canvas.save();
        canvas.clipPath(maskClipPath(mask, size));
      }
      for (final copy in symmetryCopies(controller.activeSymmetryFolds)) {
        canvas.save();
        applySymmetryTransform(canvas, center, copy);
        StrokeRenderer.draw(canvas, stroke);
        canvas.restore();
      }
      if (mask != null) canvas.restore();
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
