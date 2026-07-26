import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// A piece of a paint layer, kept so it can be put back.
///
/// Undo used to hold a clone of the *whole* layer per step — 2048 × 1536 × 4
/// = 12.58 MB whether the child drew a line across the picture or a dot. A
/// stroke almost always touches a small part of the paper, so a step is
/// stored as the pixels of that part plus where they belong.
///
/// Three shapes, and the difference matters:
///
/// * [rect] null — the layer itself was absent. An empty canvas is `null`,
///   not a transparent image, and the whole app asks `paintLayer == null`
///   to decide whether there is anything to save. Restoring has to give
///   back that exact `null`, so "there was no layer" is its own case rather
///   than a transparent patch over everything.
/// * [rect] set, [patch] null — that area was transparent. Restoring clears
///   it.
/// * both set — that area held these pixels.
class LayerPatch {
  const LayerPatch(this.patch, this.rect);

  /// The state "there was no layer at all".
  const LayerPatch.absent()
      : patch = null,
        rect = null;

  final ui.Image? patch;
  final ui.Rect? rect;

  /// What this costs the undo budget. The whole point of the exercise.
  int get bytes => patch == null ? 0 : patch!.width * patch!.height * 4;

  void dispose() => patch?.dispose();
}

/// Snaps [rect] outwards to whole pixels and clips it to the canvas.
///
/// Outwards, never inwards: a rect half a pixel too small leaves a seam of
/// stale pixels behind on undo, and that is the one way this whole
/// mechanism can go wrong quietly.
ui.Rect clampDirtyRect(ui.Rect rect, int width, int height) {
  final r = ui.Rect.fromLTRB(
    rect.left.floorToDouble(),
    rect.top.floorToDouble(),
    rect.right.ceilToDouble(),
    rect.bottom.ceilToDouble(),
  ).intersect(ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  // An off-canvas op leaves an empty rect; give back something degenerate
  // but valid rather than a negative-sized one.
  return ui.Rect.fromLTWH(
    r.left,
    r.top,
    math.max(0, r.width),
    math.max(0, r.height),
  );
}

/// Lifts the pixels of [rect] out of [layer], ready to be put back later.
///
/// A `null` layer, or an empty rect, yields a patch with no image — there
/// is nothing there to remember.
LayerPatch cropPatch(ui.Image? layer, ui.Rect rect) {
  if (layer == null) return const LayerPatch.absent();
  final w = rect.width.round();
  final h = rect.height.round();
  if (w <= 0 || h <= 0) return LayerPatch(null, rect);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  canvas.drawImageRect(
    layer,
    rect,
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint(),
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(w, h);
  picture.dispose();
  return LayerPatch(image, rect);
}

/// Puts [entry] back into [layer], returning a NEW layer; the caller still
/// owns [layer] and disposes it.
///
/// `null` comes back as `null` — see [LayerPatch].
ui.Image? applyPatch({
  required ui.Image? layer,
  required LayerPatch entry,
  required int width,
  required int height,
}) {
  final rect = entry.rect;
  if (rect == null) return null;
  if (rect.isEmpty) return layer?.clone();

  final bounds = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, bounds);
  // The clear has to bite into a layer of its own, or it would punch a hole
  // through everything painted underneath — the same reason the eraser
  // stroke wraps itself in `saveLayer` in op_apply.dart.
  canvas.saveLayer(bounds, Paint());
  if (layer != null) canvas.drawImage(layer, ui.Offset.zero, Paint());
  canvas.drawRect(rect, Paint()..blendMode = ui.BlendMode.clear);
  final patch = entry.patch;
  if (patch != null) {
    canvas.drawImageRect(
      patch,
      ui.Rect.fromLTWH(0, 0, patch.width.toDouble(), patch.height.toDouble()),
      rect,
      Paint(),
    );
  }
  canvas.restore();
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}
