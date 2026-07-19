import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../util/image_io.dart';
import '../util/svg_raster.dart';
import 'edge_detect.dart';

/// A photo decoded and letterboxed onto white at detection resolution. The
/// raw RGBA is kept so switching detail presets re-runs only the detection,
/// not the decode.
class PhotoEdgeSource {
  final Uint8List rgba;
  final int width;
  final int height;
  const PhotoEdgeSource(this.rgba, this.width, this.height);
}

/// Decodes a picked photo capped at [width] (memory bound for huge photos)
/// and contain-fits it onto a white [width]x[height] canvas. Deliberately no
/// blurred cover bars (unlike normalizePhoto) — they would produce ghost
/// edges.
Future<PhotoEdgeSource> prepareEdgeSource(Uint8List photoBytes,
    {int width = 1024, int height = 768}) async {
  final codec = await ui.instantiateImageCodec(photoBytes, targetWidth: width);
  final frame = await codec.getNextFrame();
  final photo = frame.image;
  final dst = ui.Size(width.toDouble(), height.toDouble());
  final src = ui.Size(photo.width.toDouble(), photo.height.toDouble());

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Offset.zero & dst);
  canvas.drawRect(
      ui.Offset.zero & dst, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  canvas.drawImageRect(
      photo,
      ui.Rect.fromLTWH(0, 0, src.width, src.height),
      containRect(src, dst),
      ui.Paint()..filterQuality = ui.FilterQuality.medium);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  photo.dispose();

  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return PhotoEdgeSource(data!.buffer.asUint8List(), width, height);
}

/// Runs the pure edge detection in a background isolate.
Future<Uint8List> detectMask(PhotoEdgeSource source, LineArtDetail detail) {
  final rgba = source.rgba;
  final w = source.width, h = source.height;
  final threshold = thresholdFor(detail);
  return Isolate.run(() =>
      detectEdges(rgba: rgba, width: w, height: h, threshold: threshold));
}

/// The mask as a black-on-transparent image at detection resolution (used
/// for the live preview).
Future<ui.Image> maskToImage(Uint8List mask, int width, int height) =>
    rgbaToImage(maskToRgba(mask, width, height), width, height);

/// Upscales the detected mask to canvas resolution and packages it as line
/// art. The anti-aliased upscale produces the soft alpha fringe the fill
/// dilation expects (flood_fill dilates where barrierAlpha > 0) — same
/// behavior as rasterized SVG pages. No vector picture: the painter falls
/// back to the raster.
Future<RasterizedLineArt> maskToLineArt(
    Uint8List mask, int srcWidth, int srcHeight,
    {required int canvasWidth, required int canvasHeight}) async {
  final small = await maskToImage(mask, srcWidth, srcHeight);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder,
      ui.Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()));
  canvas.drawImageRect(
      small,
      ui.Rect.fromLTWH(0, 0, srcWidth.toDouble(), srcHeight.toDouble()),
      ui.Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium);
  final picture = recorder.endRecording();
  final image = await picture.toImage(canvasWidth, canvasHeight);
  picture.dispose();
  small.dispose();
  return _withBarrierAlpha(image, canvasWidth, canvasHeight);
}

/// Rebuilds line art from a saved lineart.png (resume/share): the PNG's
/// alpha channel is the flood-fill barrier, same extraction as
/// rasterizeSvgAsset.
Future<RasterizedLineArt> lineArtFromPng(Uint8List pngBytes) async {
  final image = await pngBytesToImage(pngBytes);
  return _withBarrierAlpha(image, image.width, image.height);
}

Future<RasterizedLineArt> _withBarrierAlpha(
    ui.Image image, int width, int height) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = data!.buffer.asUint8List();
  final alpha = Uint8List(width * height);
  for (var i = 0; i < alpha.length; i++) {
    alpha[i] = rgba[i * 4 + 3];
  }
  return RasterizedLineArt(image, alpha, null, null);
}
