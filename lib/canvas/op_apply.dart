import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../models/tool.dart';
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

ui.Offset _center(int w, int h) => ui.Offset(w / 2, h / 2);

ui.Image applyStroke({
  required ui.Image? layer,
  required Stroke stroke,
  required int symmetryFolds,
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, _bounds(width, height));
  final erasing = stroke.kind == ToolKind.eraser;
  if (erasing) canvas.saveLayer(_bounds(width, height), Paint());
  if (layer != null) canvas.drawImage(layer, Offset.zero, Paint());
  for (final copy in symmetryCopies(symmetryFolds)) {
    canvas.save();
    applySymmetryTransform(canvas, _center(width, height), copy);
    StrokeRenderer.draw(canvas, stroke);
    canvas.restore();
  }
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
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, _bounds(width, height));
  if (layer != null) canvas.drawImage(layer, Offset.zero, Paint());
  for (final copy in symmetryCopies(symmetryFolds)) {
    // Transform the position, not the canvas — motifs stay upright.
    final p = symmetryPoint(pos, _center(width, height), copy);
    if (image != null) {
      StrokeRenderer.drawImageStamp(canvas, image, p, size);
    } else {
      StrokeRenderer.drawStamp(canvas, emoji ?? '⭐', p, size);
    }
  }
  final picture = recorder.endRecording();
  final result = picture.toImageSync(width, height);
  picture.dispose();
  return result;
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
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, _bounds(width, height));
  if (layer != null) canvas.drawImage(layer, Offset.zero, Paint());
  ShapeRenderer.drawShape(canvas, kind, center, radius, color, strokeWidth);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}
