import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/stickers/sticker_store.dart';
import 'package:pixiepaint/util/image_io.dart';
import 'package:pixiepaint/util/pdf_export.dart';

/// The cut-out sheet is the one export whose length depends on what a child
/// happens to own — up to [StickerStore.maxStickers] of them. On a single
/// PDF page the ones past the bottom edge are still *drawn*, just outside
/// the paper, so they print as nothing at all and nothing says so. This is
/// the test that counts pages.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List sticker;

  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder, const Rect.fromLTWH(0, 0, 64, 64))
        .drawCircle(const Offset(32, 32), 30, Paint()..color = const Color(0xFFFF8800));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(64, 64);
    picture.dispose();
    sticker = await imageToPngBytes(image);
    image.dispose();
  });

  Future<int> pagesFor(int count) async {
    final doc = stickerSheetDocument(List.filled(count, sticker));
    // The layout only happens on save; the page count before that is a lie.
    await doc.save();
    return doc.document.pdfPageList.pages.length;
  }

  test('a handful fits on one sheet', () async {
    expect(await pagesFor(6), 1);
  });

  test('a full album runs on to a second sheet instead of falling off it',
      () async {
    expect(await pagesFor(StickerStore.maxStickers), greaterThan(1));
  });

  test('every sticker in between gets a place on some page', () async {
    // Twelve is roughly where one A4 page fills up, so this walks across the
    // boundary rather than only looking at the two ends of it.
    for (final count in [10, 11, 12, 13, 14, 20]) {
      expect(await pagesFor(count), greaterThanOrEqualTo((count / 12).ceil()),
          reason: '$count stickers need more room than that');
    }
  });

  test('no stickers, no document to print', () async {
    expect(await pagesFor(0), 0);
  });
}
