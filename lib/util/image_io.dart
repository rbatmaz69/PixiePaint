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

/// Stitches two side-by-side painter panes into one artwork: the left paint
/// layer at x=0, the right at x=[paneWidth], on white paper. Used by the
/// two-painter mode, which saves a single merged picture.
Future<ui.Image> composeTwoPainterArtwork({
  required ui.Image? left,
  required ui.Image? right,
  int paneWidth = 1024,
  int height = 1536,
}) async {
  final w = paneWidth * 2;
  final recorder = ui.PictureRecorder();
  final rect = ui.Rect.fromLTWH(0, 0, w.toDouble(), height.toDouble());
  final canvas = ui.Canvas(recorder, rect);
  canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  final paint = ui.Paint();
  if (left != null) canvas.drawImage(left, ui.Offset.zero, paint);
  if (right != null) {
    canvas.drawImage(right, ui.Offset(paneWidth.toDouble(), 0), paint);
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, height);
  picture.dispose();
  return image;
}

/// The image's alpha channel as one byte per pixel — the shape the flood
/// fill barrier and the tracing coverage grid both expect.
Future<Uint8List> alphaChannelOf(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = data!.buffer.asUint8List();
  final alpha = Uint8List(image.width * image.height);
  for (var i = 0; i < alpha.length; i++) {
    alpha[i] = rgba[i * 4 + 3];
  }
  return alpha;
}

Future<ui.Image> rgbaToImage(Uint8List rgba, int width, int height) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
      rgba, width, height, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}

/// Letterbox math: the largest centered rect with [src]'s aspect ratio that
/// fits into [dst]. Pure function for unit testing.
ui.Rect containRect(ui.Size src, ui.Size dst) {
  final scale = (dst.width / src.width) < (dst.height / src.height)
      ? dst.width / src.width
      : dst.height / src.height;
  final w = src.width * scale;
  final h = src.height * scale;
  return ui.Rect.fromLTWH((dst.width - w) / 2, (dst.height - h) / 2, w, h);
}

/// Decodes a picked photo (any format the platform supports) and normalizes
/// it onto a [width]x[height] canvas: blurred cover-fill bars behind a
/// contain-fit image. Decode is capped at the canvas width so huge photos
/// don't blow memory.
Future<ui.Image> normalizePhoto(Uint8List bytes, int width, int height) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
  final frame = await codec.getNextFrame();
  final photo = frame.image;

  final dst = ui.Size(width.toDouble(), height.toDouble());
  final src = ui.Size(photo.width.toDouble(), photo.height.toDouble());
  final srcRect = ui.Rect.fromLTWH(0, 0, src.width, src.height);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Offset.zero & dst);
  canvas.drawRect(
      ui.Offset.zero & dst, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  // Blurred cover pass for pretty bars where the photo doesn't reach.
  final coverScale = (dst.width / src.width) > (dst.height / src.height)
      ? dst.width / src.width
      : dst.height / src.height;
  final coverW = src.width * coverScale;
  final coverH = src.height * coverScale;
  final coverRect = ui.Rect.fromLTWH(
      (dst.width - coverW) / 2, (dst.height - coverH) / 2, coverW, coverH);
  canvas.drawImageRect(
      photo,
      srcRect,
      coverRect,
      ui.Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30)
        ..filterQuality = ui.FilterQuality.low);
  canvas.drawImageRect(photo, srcRect, containRect(src, dst),
      ui.Paint()..filterQuality = ui.FilterQuality.medium);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  photo.dispose();
  return image;
}

/// Composites paper + paint + line art into one opaque image, optionally
/// scaled down (used for thumbnails and export).
Future<ui.Image> composeArtwork({
  required int width,
  required int height,
  ui.Image? background,
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
  if (background != null) canvas.drawImage(background, ui.Offset.zero, paint);
  if (paintLayer != null) canvas.drawImage(paintLayer, ui.Offset.zero, paint);
  if (lineArt != null) canvas.drawImage(lineArt, ui.Offset.zero, paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  picture.dispose();
  return image;
}
