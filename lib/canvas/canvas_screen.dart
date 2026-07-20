import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../gallery/artwork_store.dart';
import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../models/coloring_page.dart';
import '../models/tool.dart';
import '../photo/photo_lineart.dart';
import '../ui/app_theme.dart';
import '../ui/bouncy.dart';
import '../ui/loading_pixie.dart';
import '../models/reward.dart';
import '../ui/reward_reveal.dart';
import '../util/image_io.dart';
import '../util/progress.dart';
import '../util/review.dart';
import '../util/sfx.dart';
import '../util/share.dart' as share_util;
import '../util/svg_raster.dart';
import '../widgets/color_palette.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/parental_gate.dart';
import '../widgets/shape_picker.dart' as shapes;
import '../widgets/tool_bar.dart';
import 'canvas_controller.dart';
import 'canvas_viewport.dart';
import 'painting_canvas.dart';

const int kCanvasWidth = 2048;
const int kCanvasHeight = 1536;

/// The drawing screen: pass [page] to color a bundled picture, [resume] to
/// continue a saved artwork, [photoPath] to paint over a picked photo,
/// [photoLineArt] to color line art detected from a photo, nothing for free
/// drawing.
class CanvasScreen extends StatefulWidget {
  const CanvasScreen(
      {super.key, this.page, this.resume, this.photoPath, this.photoLineArt});

  final ColoringPage? page;
  final Artwork? resume;
  final String? photoPath;

  /// Ownership passes to the canvas controller, which disposes it.
  final RasterizedLineArt? photoLineArt;

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with WidgetsBindingObserver {
  late final CanvasController controller;
  final CanvasViewportController viewport = CanvasViewportController();
  late final String artworkId;
  String? pageId;
  late bool hasPhoto;
  late bool hasPhotoLineArt;
  late bool _backgroundSaved;
  late bool _lineArtSaved;
  bool loading = true;
  bool everSaved = false;
  Timer? _autoSave;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = CanvasController(
        canvasWidth: kCanvasWidth, canvasHeight: kCanvasHeight);
    artworkId = widget.resume?.id ?? ArtworkStore.newId();
    pageId = widget.resume?.pageId ?? widget.page?.id;
    hasPhoto = widget.photoPath != null || (widget.resume?.hasPhoto ?? false);
    hasPhotoLineArt = widget.photoLineArt != null ||
        (widget.resume?.hasPhotoLineArt ?? false);
    _backgroundSaved = widget.resume?.hasPhoto ?? false;
    _lineArtSaved = widget.resume?.hasPhotoLineArt ?? false;
    everSaved = widget.resume != null;
    _load();
    _autoSave = Timer.periodic(const Duration(seconds: 30), (_) {
      if (controller.dirty) _save();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _load() async {
    if (pageId != null) {
      final page = await ColoringPage.byId(pageId!);
      if (page != null) {
        final art = await rasterizeSvgAsset(
            page.assetPath, kCanvasWidth, kCanvasHeight);
        controller.setLineArt(art);
      }
    }
    if (widget.photoLineArt != null) {
      controller.setLineArt(widget.photoLineArt!);
    } else if ((widget.resume?.hasPhotoLineArt ?? false) &&
        await widget.resume!.lineArtFile.exists()) {
      controller.setLineArt(
          await lineArtFromPng(await widget.resume!.lineArtFile.readAsBytes()));
    }
    final photoPath = widget.photoPath;
    if (photoPath != null) {
      final bytes = await File(photoPath).readAsBytes();
      controller.setBackground(
          await normalizePhoto(bytes, kCanvasWidth, kCanvasHeight));
    } else if ((widget.resume?.hasPhoto ?? false) &&
        await widget.resume!.backgroundFile.exists()) {
      final bytes = await widget.resume!.backgroundFile.readAsBytes();
      controller.setBackground(await pngBytesToImage(bytes));
    }
    final resume = widget.resume;
    if (resume != null && await resume.paintFile.exists()) {
      final bytes = await resume.paintFile.readAsBytes();
      controller.setPaintLayer(await pngBytesToImage(bytes));
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    if (!controller.dirty && everSaved) return;
    // Don't create junk artworks for an untouched canvas.
    if (controller.isEmpty && !everSaved) return;
    Uint8List? paintPng;
    final layer = controller.paintLayer;
    if (layer != null) paintPng = await imageToPngBytes(layer);
    Uint8List? backgroundPng;
    if (hasPhoto && !_backgroundSaved && controller.backgroundImage != null) {
      backgroundPng = await imageToPngBytes(controller.backgroundImage!);
    }
    Uint8List? lineArtPng;
    if (hasPhotoLineArt && !_lineArtSaved && controller.lineArt != null) {
      lineArtPng = await imageToPngBytes(controller.lineArt!);
    }
    final thumb = await composeArtwork(
      width: kCanvasWidth,
      height: kCanvasHeight,
      background: controller.backgroundImage,
      paintLayer: controller.paintLayer,
      lineArt: controller.lineArt,
      targetWidth: 360,
    );
    final thumbPng = await imageToPngBytes(thumb);
    thumb.dispose();
    await ArtworkStore.save(
      id: artworkId,
      pageId: pageId,
      hasPhoto: hasPhoto,
      hasPhotoLineArt: hasPhotoLineArt,
      width: kCanvasWidth,
      height: kCanvasHeight,
      paintPng: paintPng,
      backgroundPng: backgroundPng,
      lineArtPng: lineArtPng,
      thumbPng: thumbPng,
    );
    if (backgroundPng != null) _backgroundSaved = true;
    if (lineArtPng != null) _lineArtSaved = true;
    everSaved = true;
    controller.dirty = false;
    // A real, saved, non-empty picture counts as "finished" for the
    // sticker rewards (autosave makes this equivalent to having painted).
    if (controller.paintLayer != null) {
      Progress.instance.registerArtworkCompleted(artworkId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (controller.dirty) _save();
    }
  }

  Future<void> _share() async {
    if (!await ParentalGate.show(context)) return;
    Sfx.instance.tada();
    await share_util.shareArtwork(
      width: kCanvasWidth,
      height: kCanvasHeight,
      background: controller.backgroundImage,
      paintLayer: controller.paintLayer,
      lineArt: controller.lineArt,
    );
    if (mounted) showConfetti(context);
    await countShareAndMaybeReview();
  }

  Future<void> _leave() async {
    if (controller.dirty) await _save();
    // Sticker unlock party — only on the way out, never mid-painting.
    for (final reward in Progress.instance.takeUncelebrated()) {
      if (!mounted) break;
      await _celebrateReward(reward);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _celebrateReward(StickerReward reward) async {
    Sfx.instance.tada();
    // Confetti fires from inside the reveal (above its scrim).
    await showRewardReveal(
      context,
      emoji: reward.emoji,
      title: context.l10n.rewardUnlockedTitle,
      body: context.l10n.rewardUnlockedBody,
      buttonLabel: context.l10n.rewardUnlockedOk,
    );
  }

  @override
  void dispose() {
    _autoSave?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    controller.dispose();
    viewport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: Container(
          decoration:
              const BoxDecoration(gradient: PixieGradients.canvasBg),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: loading
                  ? KeyedSubtree(
                      key: const ValueKey('loading'), child: _buildLoading())
                  : KeyedSubtree(
                      key: const ValueKey('canvas'),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final portrait =
                              constraints.maxWidth < constraints.maxHeight;
                          return portrait
                              ? _buildPortrait()
                              : _buildLandscape();
                        },
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// While rasterizing a bundled page, show it as a sheet of paper — the
  /// Hero flight from the picker tile lands here, hiding the load time.
  Widget _buildLoading() {
    final page = widget.page;
    if (page == null) {
      return Center(child: LoadingPixie(label: context.l10n.canvasLoading));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: kCanvasWidth / kCanvasHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Hero(
              tag: page.id,
              child: SvgPicture.asset(page.assetPath, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscape() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _LeftRail(
                controller: controller,
                onBack: _leave,
                onShare: _share,
              ),
              Expanded(child: _canvasArea(portrait: false)),
            ],
          ),
        ),
        SizedBox(
          height: 76,
          child: ColorPalette(controller: controller),
        ),
      ],
    );
  }

  Widget _buildPortrait() {
    return Column(
      children: [
        Expanded(child: _canvasArea(portrait: true)),
        Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
            ],
          ),
          child: Center(
            child: ToolBarRail(
                controller: controller, direction: Axis.horizontal),
          ),
        ),
        SizedBox(
          height: 76,
          child: ColorPalette(controller: controller),
        ),
      ],
    );
  }

  Widget _canvasArea({required bool portrait}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          // The canvas as a sheet of "paper": rounded, softly shadowed.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CanvasViewport(
                viewport: viewport,
                controller: controller,
                child: PaintingCanvas(controller: controller),
              ),
            ),
          ),
          if (portrait) ...[
            Positioned(
              top: 8,
              left: 8,
              child: _RoundButton(
                icon: Icons.arrow_back_rounded,
                tooltip: context.l10n.back,
                onTap: _leave,
              ),
            ),
            Positioned(
              top: 8,
              right: 60,
              child: _RoundButton(
                icon: Icons.ios_share_rounded,
                tooltip: context.l10n.shareForParents,
                onTap: _share,
              ),
            ),
          ],
          Positioned(
            top: 8,
            right: 8,
            child: ListenableBuilder(
              listenable: viewport,
              builder: (context, _) => viewport.isZoomed
                  ? _RoundButton(
                      icon: Icons.fit_screen_rounded,
                      tooltip: context.l10n.resetView,
                      onTap: viewport.reset,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Confirmation chip after a tool change (emoji carries the info
          // for kids who can't read yet).
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(child: _ToolChip(controller: controller)),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.isFilling
                ? const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 56),
                      child: LoadingPixie(emoji: '🪣'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// White round floating button used for the canvas overlays.
class _RoundButton extends StatelessWidget {
  const _RoundButton(
      {required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Bouncy(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon,
              size: 24, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Floating pill that briefly confirms a tool change ("🖌️ Pinsel"), then
/// fades out.
class _ToolChip extends StatefulWidget {
  const _ToolChip({required this.controller});

  final CanvasController controller;

  @override
  State<_ToolChip> createState() => _ToolChipState();
}

class _ToolChipState extends State<_ToolChip> {
  late ToolKind _lastTool = widget.controller.tool;
  late String _lastStamp = widget.controller.stampEmoji;
  late ShapeKind _lastShape = widget.controller.shapeKind;
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  void _onChange() {
    final tool = widget.controller.tool;
    final stamp = widget.controller.stampEmoji;
    final shape = widget.controller.shapeKind;
    if (tool == _lastTool && stamp == _lastStamp && shape == _lastShape) {
      return;
    }
    _lastTool = tool;
    _lastStamp = stamp;
    _lastShape = shape;
    _timer?.cancel();
    setState(() => _visible = true);
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, -0.4),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                toolEmoji(_lastTool,
                    stampEmoji: _lastStamp,
                    shapeEmoji: shapes.shapeEmoji(_lastShape)),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                toolLabel(context, _lastTool),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftRail extends StatelessWidget {
  const _LeftRail(
      {required this.controller, required this.onBack, required this.onShare});

  final CanvasController controller;
  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Tooltip(
            message: context.l10n.back,
            child: Bouncy(
              onTap: onBack,
              child: Icon(Icons.arrow_back_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ToolBarRail(controller: controller),
          ),
          Tooltip(
            message: context.l10n.shareForParents,
            child: Bouncy(
              onTap: onShare,
              child: Icon(Icons.ios_share_rounded,
                  size: 26,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
