import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

class RasterizedLineArt {
  /// Raster at canvas resolution — used for thumbnails/export and as the
  /// source of the flood-fill barrier.
  final ui.Image image;

  /// Alpha channel per pixel (width*height bytes) — the flood-fill barrier.
  final Uint8List barrierAlpha;

  /// Full-canvas vector display list (fit/centering baked in). Drawing this
  /// instead of [image] keeps the outlines sharp at any zoom. Null for
  /// raster-only line art (photo line art) — the painter falls back to
  /// [image].
  final ui.Picture? picture;

  /// The inner SVG picture; retained because [picture] may reference it.
  final ui.Picture? sourcePicture;

  const RasterizedLineArt(
      this.image, this.barrierAlpha, this.picture, this.sourcePicture);

  void dispose() {
    image.dispose();
    picture?.dispose();
    sourcePicture?.dispose();
  }
}

/// Rasterizes a bundled SVG onto a transparent [width]x[height] canvas,
/// scaled to fit and centered.
Future<RasterizedLineArt> rasterizeSvgAsset(
    String assetPath, int width, int height) async {
  final info = await vg.loadPicture(SvgAssetLoader(assetPath), null);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  final scale = min(width / info.size.width, height / info.size.height);
  canvas.translate((width - info.size.width * scale) / 2,
      (height - info.size.height * scale) / 2);
  canvas.scale(scale);
  canvas.drawPicture(info.picture);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);

  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = data!.buffer.asUint8List();
  final alpha = Uint8List(width * height);
  for (var i = 0; i < alpha.length; i++) {
    alpha[i] = rgba[i * 4 + 3];
  }
  return RasterizedLineArt(image, alpha, picture, info.picture);
}
