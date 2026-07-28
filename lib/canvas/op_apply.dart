import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../models/mask.dart';
import '../models/tool.dart';
import '../util/image_io.dart';
import 'fill_pattern.dart';
import 'flood_fill.dart' as ff;
import 'magic_wand.dart' as wand;
import 'mask_path.dart';
import 'shape_renderer.dart';
import 'stroke.dart';
import 'stroke_renderer.dart';
import 'symmetry.dart';

/// The single place where committed operations are baked onto the paint
/// layer — used by CanvasController (live drawing) AND the replay engine,
/// so the time-lapse can never diverge from what the kid actually painted.
///
/// Every function returns a NEW layer image; the caller owns disposal of
/// the old one.

ui.Rect _bounds(int w, int h) =>
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());

/// Confines everything drawn inside [body] to the masking tape.
///
/// Every operation goes through here, which is what makes the tape a
/// property of the paper rather than a feature of one tool: whatever a child
/// reaches for next, it stops at the same edge.
void _masked(ui.Canvas canvas, Mask? mask, int width, int height,
    void Function() body) {
  if (mask == null) {
    body();
    return;
  }
  canvas.save();
  canvas.clipPath(maskClipPath(mask, ui.Size(width.toDouble(), height.toDouble())));
  body();
  canvas.restore();
}

ui.Offset _center(int w, int h) => ui.Offset(w / 2, h / 2);

ui.Image applyStroke({
  required ui.Image? layer,
  required Stroke stroke,
  required int symmetryFolds,
  required int width,
  required int height,
  Mask? mask,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, _bounds(width, height));
  final erasing = stroke.kind == ToolKind.eraser;
  if (erasing) canvas.saveLayer(_bounds(width, height), Paint());
  if (layer != null) canvas.drawImage(layer, Offset.zero, Paint());
  // The eraser is masked like everything else: with tape down, "rub it all
  // out" spares what the tape covers, which is what tape is for.
  _masked(canvas, mask, width, height, () {
    for (final copy in symmetryCopies(symmetryFolds)) {
      canvas.save();
      applySymmetryTransform(canvas, _center(width, height), copy);
      StrokeRenderer.draw(canvas, stroke);
      canvas.restore();
    }
  });
  if (erasing) canvas.restore();
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}

/// [image] wins over [emoji] when both are given (custom sticker stamp).
ui.Image applyStamp({
  required ui.Image? layer,
  String? emoji,
  ui.Image? image,
  required Offset pos,
  required double size,
  required int symmetryFolds,
  required int width,
  required int height,
  Mask? mask,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, _bounds(width, height));
  if (layer != null) canvas.drawImage(layer, Offset.zero, Paint());
  _masked(canvas, mask, width, height, () {
    for (final copy in symmetryCopies(symmetryFolds)) {
      // Transform the position, not the canvas — motifs stay upright.
      final p = symmetryPoint(pos, _center(width, height), copy);
      if (image != null) {
        StrokeRenderer.drawImageStamp(canvas, image, p, size);
      } else {
        StrokeRenderer.drawStamp(canvas, emoji ?? '⭐', p, size);
      }
    }
  });
  final picture = recorder.endRecording();
  final result = picture.toImageSync(width, height);
  picture.dispose();
  return result;
}

/// Writes a word onto the layer, mirrored by the magic mirror like a stamp.
ui.Image applyText({
  required ui.Image? layer,
  required String text,
  required Offset pos,
  required double size,
  required Color color,
  required int symmetryFolds,
  required int width,
  required int height,
  Mask? mask,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, _bounds(width, height));
  if (layer != null) canvas.drawImage(layer, Offset.zero, Paint());
  _masked(canvas, mask, width, height, () {
    for (final copy in symmetryCopies(symmetryFolds)) {
      // Position mirrored, glyphs upright — exactly as for a stamp. A
      // mirrored word is unreadable, and unreadable is not what a name is
      // for.
      final p = symmetryPoint(pos, _center(width, height), copy);
      StrokeRenderer.drawText(canvas, text, p, size, color);
    }
  });
  final picture = recorder.endRecording();
  final result = picture.toImageSync(width, height);
  picture.dispose();
  return result;
}

/// Runs a flood fill in an isolate and returns the new layer, or null when
/// the fill was a no-op (seed on a wall, region already that color).
///
/// Shared by the live canvas and the replay so a time-lapse fills exactly
/// what the kid filled — the same guarantee the stroke/stamp/shape helpers
/// above provide.
Future<ui.Image?> applyFill({
  required ui.Image? layer,
  required Uint8List? barrierAlpha,
  required Offset pos,
  required Color color,
  required FillPattern pattern,
  required int width,
  required int height,
  Mask? mask,
}) async {
  Uint8List rgba;
  if (layer != null) {
    final data = await layer.toByteData(format: ui.ImageByteFormat.rawRgba);
    rgba = data!.buffer.asUint8List();
  } else {
    rgba = Uint8List(width * height * 4);
  }
  final seedX = pos.dx.floor().clamp(0, width - 1);
  final seedY = pos.dy.floor().clamp(0, height - 1);
  final result = await Isolate.run(() => ff.floodFill(
        rgba: rgba,
        barrierAlpha: barrierAlpha,
        width: width,
        height: height,
        seedX: seedX,
        seedY: seedY,
        fillR: (color.r * 255).round(),
        fillG: (color.g * 255).round(),
        fillB: (color.b * 255).round(),
        tolerance: kFillTolerance,
        // Without line art there is nothing to hide the dilation under.
        dilationPasses: barrierAlpha == null ? 0 : 3,
        pattern: pattern,
      ));
  if (result == null) return null;
  final filled = await rgbaToImage(result, width, height);
  if (mask == null) return filled;
  // The fill itself runs to the nearest line as it always does; the tape is
  // applied to what came back. Making the tape a wall *inside* the isolate
  // would change what the bucket does rather than what it covers, and the
  // pixels along that wall would come out a different colour than the same
  // fill without tape.
  return _throughTape(layer, filled, mask, width, height);
}

/// Runs the magic wand in an isolate and returns the new layer, or null when
/// there was nothing to recolour (bare paper, or already that colour).
///
/// Shares the shape of [applyFill] for the same reason: the replay has to
/// recolour exactly what the child recoloured.
Future<ui.Image?> applyWand({
  required ui.Image? layer,
  required Offset pos,
  required Color color,
  required int width,
  required int height,
  Mask? mask,
}) async {
  // No layer means nothing has been painted yet, and the wand only ever
  // touches paint.
  if (layer == null) return null;
  final data = await layer.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = data!.buffer.asUint8List();
  final seedX = pos.dx.floor().clamp(0, width - 1);
  final seedY = pos.dy.floor().clamp(0, height - 1);
  final result = await Isolate.run(() => wand.magicRecolor(
        rgba: rgba,
        width: width,
        height: height,
        seedX: seedX,
        seedY: seedY,
        toR: (color.r * 255).round(),
        toG: (color.g * 255).round(),
        toB: (color.b * 255).round(),
      ));
  if (result == null) return null;
  final recoloured = await rgbaToImage(result, width, height);
  if (mask == null) return recoloured;
  // Under tape the wand repairs only what the tape lets it reach — the same
  // edge every other tool stops at.
  return _throughTape(layer, recoloured, mask, width, height);
}

/// Lays [painted] over [layer], but only where the tape allows.
///
/// For the two tools that compute their result as a whole new layer in an
/// isolate: they cannot be clipped while they work, so they are clipped
/// afterwards.
ui.Image _throughTape(
    ui.Image? layer, ui.Image painted, Mask mask, int width, int height) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, _bounds(width, height));
  if (layer != null) canvas.drawImage(layer, Offset.zero, Paint());
  _masked(canvas, mask, width, height, () {
    canvas.drawImage(painted, Offset.zero, Paint());
  });
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  painted.dispose();
  return image;
}

ui.Image applyShape({
  required ui.Image? layer,
  required ShapeKind kind,
  required Offset center,
  required double radius,
  required Color color,
  required double strokeWidth,
  required int width,
  required int height,
  double angle = 0,
  bool outline = false,
  Mask? mask,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, _bounds(width, height));
  if (layer != null) canvas.drawImage(layer, Offset.zero, Paint());
  _masked(canvas, mask, width, height, () {
    ShapeRenderer.drawShape(canvas, kind, center, radius, color, strokeWidth,
        angle: angle, outline: outline);
  });
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}
