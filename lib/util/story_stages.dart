import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../canvas/op_apply.dart';
import '../canvas/stroke.dart';
import '../models/artwork.dart';
import '../models/coloring_page.dart';
import '../models/draw_op.dart';
import '../photo/photo_lineart.dart';
import 'image_io.dart';
import 'svg_raster.dart';

/// The picture at a few points along its own story.
///
/// The time-lapse has been in the app since v6.3 and it is a dead end: a
/// parent can watch it once and that is all. These are the same operations,
/// replayed to a handful of checkpoints and handed back as pictures — which
/// can be printed, pinned up and kept.
///
/// The walk over the ops is its own here rather than shared with
/// `ReplayController`: that one *animates* every stroke point by point and
/// needs the per-kind branches for it, while this one only wants the layer
/// as it stood. What has to be identical is what each op *does*, and that
/// is `op_apply`, which both call.
Future<List<Uint8List>> storyStages(
  Artwork artwork, {
  int count = 6,
  int targetWidth = 720,
}) async {
  final ops = await _readOps(artwork);
  final w = artwork.width;
  final h = artwork.height;

  ui.Image? background;
  RasterizedLineArt? raster;
  ui.Image? layer;
  final stickers = <String, ui.Image?>{};
  final stages = <Uint8List>[];

  Future<void> snapshot() async {
    final composed = await composeArtwork(
      width: w,
      height: h,
      background: background,
      paintLayer: layer,
      lineArt: raster?.image,
      targetWidth: targetWidth,
    );
    stages.add(await imageToPngBytes(composed));
    composed.dispose();
  }

  try {
    if (artwork.hasPhoto && await artwork.backgroundFile.exists()) {
      background =
          await pngBytesToImage(await artwork.backgroundFile.readAsBytes());
    }
    if (artwork.pageId != null) {
      final page = await ColoringPage.byId(artwork.pageId!);
      if (page != null) {
        raster = await rasterizeSvgAsset(page.assetPath, w, h);
      }
    } else if (artwork.hasPhotoLineArt && await artwork.lineArtFile.exists()) {
      raster = await lineArtFromPng(await artwork.lineArtFile.readAsBytes());
    }

    // The page as the child found it is the first frame. "Before" is half of
    // what makes a strip worth looking at — see the before/after wipe, same
    // idea.
    //
    // For a scratch picture that is not the empty layer: the first op is the
    // cover, which is how the picture *arrived* rather than something the
    // child did. Photographing before it would open the strip on the bare
    // colour sheet — the one page they never saw, and the answer to the
    // riddle printed above the riddle.
    final arrival = artwork.scratch && ops.isNotEmpty ? 1 : 0;
    if (arrival == 0) await snapshot();

    final cuts = _checkpoints(ops.length, count - 1, from: arrival);
    for (var i = 0; i < ops.length; i++) {
      final next = await _apply(
        ops[i],
        layer: layer,
        barrierAlpha: raster?.barrierAlpha,
        width: w,
        height: h,
        stickers: stickers,
      );
      if (next.changed) {
        layer?.dispose();
        layer = next.layer;
      }
      if (i == arrival - 1) await snapshot();
      if (cuts.contains(i)) await snapshot();
    }
    // Whatever the arithmetic did, the last frame is the finished picture.
    if (ops.isEmpty || !cuts.contains(ops.length - 1)) await snapshot();
    return stages;
  } finally {
    background?.dispose();
    raster?.dispose();
    layer?.dispose();
    for (final image in stickers.values) {
      image?.dispose();
    }
  }
}

/// Which op indices to photograph, spread over the story from [from] on.
///
/// [from] skips the ops a picture arrived with rather than earned — today
/// only the cover of a scratch picture.
Set<int> _checkpoints(int total, int wanted, {int from = 0}) {
  final span = total - from;
  if (span <= 0 || wanted <= 0) return const {};
  if (span <= wanted) return {for (var i = from; i < total; i++) i};
  return {
    for (var k = 1; k <= wanted; k++) from + (span * k / wanted).round() - 1,
  };
}

Future<List<DrawOp>> _readOps(Artwork artwork) async {
  try {
    if (!await artwork.opsFile.exists()) return const [];
    return decodeOps(await artwork.opsFile.readAsString());
  } catch (_) {
    return const [];
  }
}

/// [changed] is false where an op did nothing at all — a fill on a wall, a
/// wand tap on bare paper. The layer then stays exactly as it was, and the
/// caller must not dispose it.
Future<({ui.Image? layer, bool changed})> _apply(
  DrawOp op, {
  required ui.Image? layer,
  required Uint8List? barrierAlpha,
  required int width,
  required int height,
  required Map<String, ui.Image?> stickers,
}) async {
  switch (op) {
    case StrokeOp():
      final stroke = Stroke(
        kind: op.toolKind,
        color: Color(op.color),
        baseWidth: op.baseWidth,
        seed: op.seed,
      );
      for (var i = 0; i + 2 < op.points.length; i += 3) {
        stroke.points.add(StrokePoint(
            Offset(op.points[i], op.points[i + 1]), op.points[i + 2]));
      }
      if (stroke.points.isEmpty) return (layer: layer, changed: false);
      return (
        layer: applyStroke(
          layer: layer,
          stroke: stroke,
          symmetryFolds: op.symmetryFolds,
          width: width,
          height: height,
          mask: op.mask,
        ),
        changed: true
      );
    case StampOp():
      ui.Image? sticker;
      final path = op.imagePath;
      if (path != null) {
        sticker = stickers.putIfAbsent(path, () => null);
        if (sticker == null) {
          sticker = await _sticker(path);
          stickers[path] = sticker;
        }
      }
      return (
        layer: applyStamp(
          layer: layer,
          emoji: sticker == null ? (op.emoji ?? '⭐') : null,
          image: sticker,
          pos: Offset(op.x, op.y),
          size: op.size,
          symmetryFolds: op.symmetryFolds,
          width: width,
          height: height,
          mask: op.mask,
        ),
        changed: true
      );
    case ShapeOp():
      return (
        layer: applyShape(
          layer: layer,
          kind: op.kind,
          center: Offset(op.x, op.y),
          radius: op.radius,
          color: Color(op.color),
          strokeWidth: op.strokeWidth,
          angle: op.angle,
          outline: op.outline,
          width: width,
          height: height,
          mask: op.mask,
        ),
        changed: true
      );
    case TextOp():
      return (
        layer: applyText(
          layer: layer,
          text: op.text,
          pos: Offset(op.x, op.y),
          size: op.size,
          color: Color(op.color),
          symmetryFolds: op.symmetryFolds,
          width: width,
          height: height,
          mask: op.mask,
        ),
        changed: true
      );
    case FillOp():
      final filled = await applyFill(
        layer: layer,
        barrierAlpha: barrierAlpha,
        pos: Offset(op.x, op.y),
        color: Color(op.color),
        pattern: op.pattern,
        width: width,
        height: height,
        mask: op.mask,
      );
      return filled == null
          ? (layer: layer, changed: false)
          : (layer: filled, changed: true);
    case WandOp():
      final recoloured = await applyWand(
        layer: layer,
        pos: Offset(op.x, op.y),
        color: Color(op.color),
        width: width,
        height: height,
        mask: op.mask,
      );
      return recoloured == null
          ? (layer: layer, changed: false)
          : (layer: recoloured, changed: true);
    case ClearOp():
      return (layer: null, changed: true);
  }
}

Future<ui.Image?> _sticker(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await pngBytesToImage(await file.readAsBytes());
  } catch (_) {
    return null;
  }
}
