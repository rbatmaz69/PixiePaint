import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/artwork.dart';
import '../models/coloring_page.dart';
import 'image_io.dart';
import 'share.dart';
import 'story_stages.dart';
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

/// Prints the picture's own story: the empty page, four steps along the way
/// and the finished thing, in order, on one sheet.
///
/// The time-lapse could only ever be watched. This is the same story in a
/// form that can go on a fridge — and it is the one export that shows what a
/// child *did* rather than what they ended up with.
Future<void> printStoryStrip(Artwork artwork, {String? title}) async {
  final stages = await storyStages(artwork);
  final doc = pw.Document();
  final images = [for (final png in stages) pw.MemoryImage(png)];
  final date = artwork.updatedAt;
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (title != null && title.isNotEmpty)
            pw.Text(title, style: const pw.TextStyle(fontSize: 20)),
          pw.Text(
            '${date.day}.${date.month}.${date.year}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 10),
          pw.Expanded(
            child: pw.GridView(
              crossAxisCount: 3,
              childAspectRatio: 4 / 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                for (var i = 0; i < images.length; i++)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Stack(
                      children: [
                        pw.Positioned.fill(
                          child: pw.Image(images[i], fit: pw.BoxFit.contain),
                        ),
                        // The number is what makes it a sequence rather than
                        // six similar pictures.
                        pw.Positioned(
                          left: 4,
                          top: 4,
                          child: pw.Text('${i + 1}',
                              style: const pw.TextStyle(
                                  fontSize: 12, color: PdfColors.grey600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(
    name: 'pixiepaint_story_${artwork.id.substring(0, 8)}',
    onLayout: (_) => doc.save(),
  );
}

/// Prints the picture as a folding card: A4 landscape, folded down the
/// middle, the drawing on the front and the inside left blank to write in.
///
/// A picture a child gives away is a different object than one that goes in
/// a folder, and until now the app could only make the second kind.
Future<void> printGreetingCard(Artwork artwork, {String? title}) async {
  final png = await composeSavedArtworkPng(artwork);
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.Stack(
        children: [
          pw.Row(
            children: [
              // The back of the card. Empty on purpose — folded, this half
              // ends up behind the drawing.
              pw.Expanded(child: pw.SizedBox()),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Expanded(
                        child: pw.Image(pw.MemoryImage(png),
                            fit: pw.BoxFit.contain),
                      ),
                      if (title != null && title.isNotEmpty) ...[
                        pw.SizedBox(height: 12),
                        pw.Text(title, style: const pw.TextStyle(fontSize: 18)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // The fold, drawn as a dashed line: without it nobody knows the
          // sheet is meant to be folded rather than cut.
          pw.Positioned(
            left: PdfPageFormat.a4.landscape.width / 2,
            top: 0,
            child: _dashedColumn(PdfPageFormat.a4.landscape.height),
          ),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(
    name: 'pixiepaint_card_${artwork.id.substring(0, 8)}',
    onLayout: (_) => doc.save(),
  );
}

/// A dashed vertical line [height] tall, built out of little boxes — the pdf
/// package has no dash pattern.
pw.Widget _dashedColumn(double height) {
  const dash = 6.0;
  final count = (height / (dash * 2)).floor();
  return pw.Column(
    children: [
      for (var i = 0; i < count; i++) ...[
        pw.Container(width: 0.8, height: dash, color: PdfColors.grey400),
        pw.SizedBox(height: dash),
      ],
    ],
  );
}

/// Prints the child's own stickers as a cut-out sheet.
///
/// Custom stickers have only ever existed inside the app. On paper they
/// become something to stick on a lunchbox — the same picture, out in the
/// world, which is the whole reason a child photographs their toys into it.
Future<void> printStickerSheet(List<File> stickers) async {
  final images = <pw.MemoryImage>[];
  for (final file in stickers) {
    try {
      images.add(pw.MemoryImage(await file.readAsBytes()));
    } catch (_) {
      // A sticker that cannot be read is left out; a broken sheet helps
      // nobody, and the rest of them are fine.
    }
  }
  if (images.isEmpty) return;
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.GridView(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          for (final image in images)
            pw.Container(
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              padding: const pw.EdgeInsets.all(6),
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(
    name: 'pixiepaint_stickers',
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
