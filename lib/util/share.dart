import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/artwork.dart';
import '../models/coloring_page.dart';
import '../photo/photo_lineart.dart';
import 'image_io.dart';
import 'svg_raster.dart';

/// Composes the full-resolution artwork and opens the system share sheet.
Future<void> shareArtwork({
  required int width,
  required int height,
  ui.Image? background,
  ui.Image? paintLayer,
  ui.Image? lineArt,
}) async {
  final composed = await composeArtwork(
    width: width,
    height: height,
    background: background,
    paintLayer: paintLayer,
    lineArt: lineArt,
  );
  final png = await imageToPngBytes(composed);
  composed.dispose();
  final tmp = await getTemporaryDirectory();
  final file = File(
      '${tmp.path}/pixiepaint_${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(png);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
  );
}

/// Composes a saved artwork into PNG bytes: loads the paint layer from disk
/// and re-rasterizes the line art if the artwork is a coloring page (photo
/// line art is reloaded from its saved PNG instead). Shared by the share
/// sheet, save-to-Photos, printing and the slideshow — the latter passes
/// [targetWidth] to get a screen-sized render instead of the full canvas.
Future<Uint8List> composeSavedArtworkPng(Artwork artwork,
    {int? targetWidth}) async {
  ui.Image? background;
  ui.Image? paintLayer;
  RasterizedLineArt? raster;
  try {
    if (artwork.hasPhoto && await artwork.backgroundFile.exists()) {
      background =
          await pngBytesToImage(await artwork.backgroundFile.readAsBytes());
    }
    if (await artwork.paintFile.exists()) {
      paintLayer = await pngBytesToImage(await artwork.paintFile.readAsBytes());
    }
    if (artwork.pageId != null) {
      final page = await ColoringPage.byId(artwork.pageId!);
      if (page != null) {
        raster = await rasterizeSvgAsset(
            page.assetPath, artwork.width, artwork.height);
      }
    } else if (artwork.hasPhotoLineArt && await artwork.lineArtFile.exists()) {
      raster = await lineArtFromPng(await artwork.lineArtFile.readAsBytes());
    }
    final composed = await composeArtwork(
      width: artwork.width,
      height: artwork.height,
      background: background,
      paintLayer: paintLayer,
      lineArt: raster?.image,
      targetWidth: targetWidth,
    );
    final png = await imageToPngBytes(composed);
    composed.dispose();
    return png;
  } finally {
    background?.dispose();
    paintLayer?.dispose();
    raster?.dispose();
  }
}

/// Shares a saved artwork straight from the gallery via the system sheet.
Future<void> shareSavedArtwork(Artwork artwork) async {
  final png = await composeSavedArtworkPng(artwork);
  final tmp = await getTemporaryDirectory();
  final file = File(
      '${tmp.path}/pixiepaint_${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(png);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
  );
}
