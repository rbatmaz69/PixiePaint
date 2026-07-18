import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

class RasterizedLineArt {
  final ui.Image image;

  /// Alpha channel per pixel (width*height bytes) — the flood-fill barrier.
  final Uint8List barrierAlpha;

  const RasterizedLineArt(this.image, this.barrierAlpha);
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
  picture.dispose();
  info.picture.dispose();

  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = data!.buffer.asUint8List();
  final alpha = Uint8List(width * height);
  for (var i = 0; i < alpha.length; i++) {
    alpha[i] = rgba[i * 4 + 3];
  }
  return RasterizedLineArt(image, alpha);
}
