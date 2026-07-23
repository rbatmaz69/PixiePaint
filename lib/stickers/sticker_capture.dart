import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../ui/kid_dialog.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/image_io.dart';
import '../util/sfx.dart';
import 'sticker_store.dart';

const int kStickerSize = 512;
const double _rimWidth = 10;

/// Full-screen capture flow: the composed artwork with a draggable,
/// pinch-resizable circle; confirming crops the circle into a 512 px round
/// sticker, saves it and selects it as the stamp motif.
Future<void> showStickerCapture(
    BuildContext context, CanvasController controller) async {
  final image = await composeArtwork(
    width: controller.canvasWidth,
    height: controller.canvasHeight,
    background: controller.backgroundImage,
    paintLayer: controller.paintLayer,
    lineArt: controller.lineArt,
  );
  if (!context.mounted) {
    image.dispose();
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _StickerCaptureScreen(image: image, controller: controller),
    ),
  );
}

class _StickerCaptureScreen extends StatefulWidget {
  const _StickerCaptureScreen({required this.image, required this.controller});

  final ui.Image image;
  final CanvasController controller;

  @override
  State<_StickerCaptureScreen> createState() => _StickerCaptureScreenState();
}

class _StickerCaptureScreenState extends State<_StickerCaptureScreen> {
  /// Circle in displayed-image coordinates.
  Offset? _center;
  double _radius = 0;
  double _startRadius = 0;
  Size _displaySize = Size.zero;
  bool _saving = false;

  @override
  void dispose() {
    widget.image.dispose();
    super.dispose();
  }

  void _clampCircle() {
    final r = _radius.clamp(40.0, _displaySize.shortestSide / 2);
    _radius = r;
    _center = Offset(
      _center!.dx.clamp(r, _displaySize.width - r),
      _center!.dy.clamp(r, _displaySize.height - r),
    );
  }

  Future<void> _confirm() async {
    if (_saving || _center == null) return;
    setState(() => _saving = true);
    final scale = widget.image.width / _displaySize.width;
    final cx = _center!.dx * scale;
    final cy = _center!.dy * scale;
    final r = _radius * scale;

    final recorder = ui.PictureRecorder();
    const size = Size(kStickerSize + 0.0, kStickerSize + 0.0);
    final canvas = Canvas(recorder, Offset.zero & size);
    final circle = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(
          center: circle, radius: size.width / 2 - _rimWidth / 2)));
    canvas.drawImageRect(
      widget.image,
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
    // White sticker rim.
    canvas.drawCircle(
        circle,
        size.width / 2 - _rimWidth / 2,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = _rimWidth);
    final picture = recorder.endRecording();
    final sticker = picture.toImageSync(kStickerSize, kStickerSize);
    picture.dispose();
    try {
      final png = await imageToPngBytes(sticker);
      sticker.dispose();

      final file = await StickerStore.save(png);
      if (!mounted) return;
      if (file == null) {
        // Storage is full or unwritable. Say so instead of leaving a
        // sticker that will never decode.
        await showKidDialog<void>(
          context: context,
          emoji: '😕',
          title: context.l10n.stickerSaveFailed,
          actions: [
            Builder(
              builder: (dialogContext) => KidDialogButton(
                label: context.l10n.okAction,
                emoji: '👍',
                onTap: () => Navigator.pop(dialogContext),
              ),
            ),
          ],
        );
        return;
      }
      final decoded = await pngBytesToImage(png);
      // Left the screen while saving — don't hand the image to a controller
      // that may already be disposed.
      if (!mounted) return decoded.dispose();
      widget.controller.selectImageStamp(file.path, decoded);
      Sfx.instance.pop();
      Navigator.of(context).pop();
    } finally {
      // Without this a failed save would wedge the ✓ button forever.
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aspect = widget.image.width / widget.image.height;
    return Scaffold(
      backgroundColor: PixiePalette.ink.withValues(alpha: 0.92),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  StickerCircleButton(
                    icon: Icons.close_rounded,
                    tooltip: context.l10n.gateCancel,
                    accent: PixiePalette.grape,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.stickerCaptureTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  StickerCircleButton(
                    icon: _saving
                        ? Icons.hourglass_top_rounded
                        : Icons.check_rounded,
                    tooltip: context.l10n.okAction,
                    accent: PixiePalette.mint,
                    onTap: _confirm,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspect,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _displaySize =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      _center ??= _displaySize.center(Offset.zero);
                      if (_radius == 0) {
                        _radius = _displaySize.shortestSide * 0.3;
                      }
                      _clampCircle();
                      return GestureDetector(
                        onScaleStart: (d) {
                          _startRadius = _radius;
                        },
                        onScaleUpdate: (d) => setState(() {
                          // scale is cumulative since gesture start,
                          // focalPointDelta is per-update — accumulate it.
                          _radius = _startRadius * d.scale;
                          _center = _center! + d.focalPointDelta;
                          _clampCircle();
                        }),
                        child: CustomPaint(
                          painter: _CapturePainter(
                              widget.image, _center!, _radius),
                          child: const SizedBox.expand(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CapturePainter extends CustomPainter {
  const _CapturePainter(this.image, this.center, this.radius);

  final ui.Image image;
  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
        0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Offset.zero & size;
    canvas.drawImageRect(
        image, src, dst, Paint()..filterQuality = FilterQuality.medium);
    // Dark scrim outside the circle.
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final scrim = Path.combine(
        PathOperation.difference, Path()..addRect(dst), hole);
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.55));
    // Circle outline with a soft glow.
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // Little size handle hint at the bottom right of the circle.
    final handle = center + Offset(cos(pi / 4), sin(pi / 4)) * radius;
    canvas.drawCircle(handle, 10, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_CapturePainter old) =>
      old.center != center || old.radius != radius || old.image != image;
}
