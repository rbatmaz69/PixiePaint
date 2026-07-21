import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/artwork.dart';
import '../models/coloring_page.dart';
import 'image_io.dart';
import 'share.dart';
import 'svg_raster.dart';

/// Print/PDF export via the native print dialog — fully offline, both entry
/// points sit behind the parental gate at the call sites.

/// Prints a saved artwork on A4 landscape with a small margin.
Future<void> printSavedArtwork(Artwork artwork) async {
  final png = await composeSavedArtworkPng(artwork);
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => pw.Center(
        child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
      ),
    ),
  );
  await Printing.layoutPdf(
    name: 'pixiepaint_${artwork.id.substring(0, 8)}',
    onLayout: (_) => doc.save(),
  );
}

/// Prints a blank coloring page for painting on real paper. Embeds the SVG
/// as vectors (crisp at any print size); falls back to a high-res raster if
/// the pdf package can't parse the SVG.
Future<void> printColoringPage(ColoringPage page) async {
  final doc = pw.Document();
  pw.Widget content;
  try {
    final svg = await rootBundle.loadString(page.assetPath);
    content = pw.SvgImage(svg: svg, fit: pw.BoxFit.contain);
  } catch (_) {
    final raster = await rasterizeSvgAsset(page.assetPath, 2048, 1536);
    final png = await imageToPngBytes(raster.image);
    raster.dispose();
    content = pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain);
  }
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Center(child: content),
    ),
  );
  await Printing.layoutPdf(
    name: 'pixiepaint_${page.id}',
    onLayout: (_) => doc.save(),
  );
}
