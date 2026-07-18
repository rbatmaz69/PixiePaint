import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Uint8List> imageToPngBytes(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<ui.Image> pngBytesToImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<ui.Image> rgbaToImage(Uint8List rgba, int width, int height) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
      rgba, width, height, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}

/// Composites paper + paint + line art into one opaque image, optionally
/// scaled down (used for thumbnails and export).
Future<ui.Image> composeArtwork({
  required int width,
  required int height,
  ui.Image? paintLayer,
  ui.Image? lineArt,
  int? targetWidth,
}) async {
  final scale = targetWidth != null ? targetWidth / width : 1.0;
  final w = (width * scale).round();
  final h = (height * scale).round();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
      recorder, ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  canvas.scale(scale);
  final paint = ui.Paint()
    ..filterQuality = scale < 1.0 ? ui.FilterQuality.medium : ui.FilterQuality.none;
  if (paintLayer != null) canvas.drawImage(paintLayer, ui.Offset.zero, paint);
  if (lineArt != null) canvas.drawImage(lineArt, ui.Offset.zero, paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  picture.dispose();
  return image;
}
