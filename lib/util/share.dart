import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'image_io.dart';

/// Composes the full-resolution artwork and opens the system share sheet.
Future<void> shareArtwork({
  required int width,
  required int height,
  ui.Image? paintLayer,
  ui.Image? lineArt,
}) async {
  final composed = await composeArtwork(
    width: width,
    height: height,
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
