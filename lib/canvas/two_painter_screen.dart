import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/profiles.dart';
import '../widgets/color_palette.dart';
import '../widgets/tool_bar.dart';
import 'canvas_controller.dart';
import 'two_painter_save.dart';
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

class _TwoPainterScreenState extends State<TwoPainterScreen>
    with WidgetsBindingObserver {
  late final CanvasController _left = _makeController();
  late final CanvasController _right = _makeController();
  bool _leftFlipped = true; // start face-to-face across the table
  bool _leaving = false;
  late final bool _simpleTools = ProfileStore.instance.active.simpleTools;

  /// All the saving rules live here, testable without a widget tree.
  late final TwoPainterSaveSession _saves = TwoPainterSaveSession(
    left: _left,
    right: _right,
    paneWidth: TwoPainterScreen.paneWidth,
    paneHeight: TwoPainterScreen.paneHeight,
  );

  Timer? _autoSave;

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
    WidgetsBinding.instance.addObserver(this);
    _autoSave = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_saves.isDirty) _saves.save();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;
    // Save first: it reads both paint layers, and releaseMemory() below
    // throws the undo history away. Twenty minutes of two kids painting
    // together used to end here whenever someone pressed home.
    if (_saves.isDirty) _saves.save();
    // Two canvases mean two undo histories. This mode is tablet-only, but a
    // tablet backgrounding two of them at once is exactly the case the
    // budget alone does not cover.
    _left.releaseMemory();
    _right.releaseMemory();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    await _saves.save();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _autoSave?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // A save in flight still reads both paint layers — free them only
    // afterwards, or it encodes disposed images. The controllers are not
    // part of the element tree, so outliving this State briefly is safe.
    final pending = _saves.pending;
    if (pending != null) {
      pending.whenComplete(() {
        _left.dispose();
        _right.dispose();
      });
    } else {
      _left.dispose();
      _right.dispose();
    }
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
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: ToolBarRail(
                  controller: controller,
                  direction: Axis.horizontal,
                  buttonSize: 50,
                  // Both panes follow the active child's profile — one of
                  // the two is holding the tablet.
                  simple: _simpleTools,
                ),
              ),
              // Half a tablet is narrow: without this, undo would be the
              // nineteenth button of a scrolling strip.
              ToolActionCluster(
                controller: controller,
                direction: Axis.horizontal,
              ),
            ],
          ),
        ),
        SizedBox(
          height: kPaletteHeight,
          child: ColorPalette(controller: controller),
        ),
      ],
    );
  }
}
