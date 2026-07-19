import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../gallery/artwork_store.dart';
import '../models/artwork.dart';
import '../models/coloring_page.dart';
import '../photo/photo_lineart.dart';
import '../util/image_io.dart';
import '../util/sfx.dart';
import '../util/share.dart' as share_util;
import '../util/svg_raster.dart';
import '../widgets/color_palette.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/parental_gate.dart';
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
  }

  Future<void> _leave() async {
    if (controller.dirty) await _save();
    if (mounted) Navigator.of(context).pop();
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
        backgroundColor: const Color(0xFFEDE7F6),
        body: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final portrait =
                        constraints.maxWidth < constraints.maxHeight;
                    return portrait ? _buildPortrait() : _buildLandscape();
                  },
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
          Positioned.fill(
            child: CanvasViewport(
              viewport: viewport,
              controller: controller,
              child: PaintingCanvas(controller: controller),
            ),
          ),
          if (portrait) ...[
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filledTonal(
                iconSize: 28,
                onPressed: _leave,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Zurück',
              ),
            ),
            Positioned(
              top: 8,
              right: 56,
              child: IconButton.filledTonal(
                iconSize: 28,
                onPressed: _share,
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Teilen (für Eltern)',
              ),
            ),
          ],
          Positioned(
            top: 8,
            right: 8,
            child: ListenableBuilder(
              listenable: viewport,
              builder: (context, _) => viewport.isZoomed
                  ? IconButton.filledTonal(
                      iconSize: 28,
                      onPressed: viewport.reset,
                      icon: const Icon(Icons.fit_screen_rounded),
                      tooltip: 'Ansicht zurücksetzen',
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.isFilling
                ? const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
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
          IconButton(
            iconSize: 30,
            padding: const EdgeInsets.all(12),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Zurück',
          ),
          Expanded(
            child: ToolBarRail(controller: controller),
          ),
          IconButton(
            iconSize: 28,
            padding: const EdgeInsets.all(12),
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Teilen (für Eltern)',
          ),
        ],
      ),
    );
  }
}
