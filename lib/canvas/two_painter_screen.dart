import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../gallery/artwork_store.dart';
import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/image_io.dart';
import '../util/profiles.dart';
import '../widgets/color_palette.dart';
import '../widgets/tool_bar.dart';
import 'canvas_controller.dart';
import 'painting_canvas.dart';

/// Two kids, one tablet: the screen splits into two independent painting
/// panes. Each pane has its own controller, tools and colors, so Flutter
/// routes every finger to the pane it landed in and the two never interfere
/// — which a single shared canvas cannot do (it tracks one active pointer
/// and reads any second touch as a pinch).
///
/// No zoom/pan here (four simultaneous fingers make pinch meaningless); each
/// pane is simply fit into its half. On leave the two paint layers are
/// stitched into one saved picture.
class TwoPainterScreen extends StatefulWidget {
  const TwoPainterScreen({super.key});

  /// Half the standard canvas — two of them stitch back to 2048×1536.
  static const int paneWidth = 1024;
  static const int paneHeight = 1536;

  @override
  State<TwoPainterScreen> createState() => _TwoPainterScreenState();
}

class _TwoPainterScreenState extends State<TwoPainterScreen> {
  late final CanvasController _left = _makeController();
  late final CanvasController _right = _makeController();
  bool _leftFlipped = true; // start face-to-face across the table
  bool _saving = false;

  CanvasController _makeController() {
    return CanvasController(
      canvasWidth: TwoPainterScreen.paneWidth,
      canvasHeight: TwoPainterScreen.paneHeight,
    )
      // The time-lapse cannot merge two op streams, so this mode does not
      // record — the recorder is opt-out per controller for exactly this.
      ..recordOps = false;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _leave() async {
    if (_saving) return;
    _saving = true;
    if (!_left.isEmpty || !_right.isEmpty) {
      try {
        final merged = await composeTwoPainterArtwork(
          left: _left.paintLayer,
          right: _right.paintLayer,
          paneWidth: TwoPainterScreen.paneWidth,
          height: TwoPainterScreen.paneHeight,
        );
        final paintPng = await imageToPngBytes(merged);
        final thumb = await composeArtwork(
          width: merged.width,
          height: merged.height,
          paintLayer: merged,
          targetWidth: 360,
        );
        final thumbPng = await imageToPngBytes(thumb);
        thumb.dispose();
        merged.dispose();
        await ArtworkStore.save(
          id: ArtworkStore.newId(),
          pageId: null,
          profileId: ProfileStore.instance.active.id,
          width: TwoPainterScreen.paneWidth * 2,
          height: TwoPainterScreen.paneHeight,
          paintPng: paintPng,
          thumbPng: thumbPng,
        );
      } catch (_) {
        // Never trap the kids on the screen because a save failed.
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _left.dispose();
    _right.dispose();
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
          decoration: const BoxDecoration(gradient: PixieGradients.canvasBg),
          child: SafeArea(
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(child: _pane(_left, flipped: _leftFlipped)),
                    Container(width: 3, color: PixiePalette.grape.withValues(alpha: 0.2)),
                    Expanded(child: _pane(_right, flipped: false)),
                  ],
                ),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StickerCircleButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: context.l10n.back,
                          accent: PixiePalette.grape,
                          onTap: _leave,
                        ),
                        const SizedBox(width: 10),
                        StickerCircleButton(
                          icon: Icons.flip_rounded,
                          tooltip: context.l10n.twoPainterFlip,
                          accent: PixiePalette.grape,
                          onTap: () =>
                              setState(() => _leftFlipped = !_leftFlipped),
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

  Widget _pane(CanvasController controller, {required bool flipped}) {
    final canvas = Center(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AspectRatio(
          aspectRatio:
              TwoPainterScreen.paneWidth / TwoPainterScreen.paneHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: PixiePalette.ink.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: TwoPainterScreen.paneWidth.toDouble(),
                height: TwoPainterScreen.paneHeight.toDouble(),
                child: PaintingCanvas(controller: controller),
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      children: [
        // Rotating the pane 180° also rotates its pointer mapping, so the
        // kid sitting opposite draws the right way up from their side.
        Expanded(
          child: RotatedBox(quarterTurns: flipped ? 2 : 0, child: canvas),
        ),
        SizedBox(
          height: 60,
          child: Center(
            child: ToolBarRail(
              controller: controller,
              direction: Axis.horizontal,
            ),
          ),
        ),
        SizedBox(height: 64, child: ColorPalette(controller: controller)),
      ],
    );
  }
}
