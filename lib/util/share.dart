import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/artwork.dart';
import '../models/coloring_page.dart';
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

/// Shares a saved artwork straight from the gallery: loads the paint layer
/// from disk and re-rasterizes the line art if the artwork is a coloring
/// page.
Future<void> shareSavedArtwork(Artwork artwork) async {
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
    }
    await shareArtwork(
      width: artwork.width,
      height: artwork.height,
      background: background,
      paintLayer: paintLayer,
      lineArt: raster?.image,
    );
  } finally {
    background?.dispose();
    paintLayer?.dispose();
    raster?.dispose();
  }
}
