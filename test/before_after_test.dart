import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/gallery/before_after_screen.dart';
import 'package:pixiepaint/models/artwork.dart';

/// The wipe has exactly one promise: left of the handle is the picture the
/// child started with, right of it is the one they finished. If any of their
/// paint leaks across, the screen says something untrue about their work.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 200;
  const h = 150;
  const canvas = Size(200, 150);

  /// An opaque red rectangle covering the whole canvas — stands in for the
  /// child's paint layer.
  ui.Image redLayer() {
    final recorder = ui.PictureRecorder();
    Canvas(recorder, const Rect.fromLTWH(0, 0, 200, 150)).drawRect(
        const Rect.fromLTWH(0, 0, 200, 150), Paint()..color = const Color(0xFFFF0000));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();
    return image;
  }

  Future<List<int>> render(double wipe) async {
    final layer = redLayer();
    final recorder = ui.PictureRecorder();
    WipePainter(
      background: null,
      paintLayer: layer,
      lineArt: null,
      canvasSize: canvas,
      wipe: wipe,
    ).paint(
        Canvas(recorder, const Rect.fromLTWH(0, 0, 200, 150)), const Size(200, 150));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();
    layer.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  /// Is the child's paint showing here? Red on the paper, and the paper
  /// itself is white — so the green channel is what tells them apart.
  bool painted(List<int> px, int x, int y) {
    final o = (y * w + x) * 4;
    return px[o] > 200 && px[o + 1] < 60;
  }

  test('a wipe at the far left shows no paint at all', () async {
    final px = await render(0);
    expect(painted(px, 5, 10), isFalse, reason: 'left edge');
    expect(painted(px, 195, 10), isFalse, reason: 'right edge');
  });

  test('a wipe at the far right shows the finished picture everywhere',
      () async {
    final px = await render(1);
    expect(painted(px, 5, 10), isTrue);
    expect(painted(px, 195, 10), isTrue);
  });

  test('halfway is painted on one side and empty on the other', () async {
    final px = await render(0.5);
    expect(painted(px, 20, 10), isTrue, reason: 'left of the handle');
    expect(painted(px, 180, 10), isFalse, reason: 'right of the handle');
  });

  group('who gets offered it', () {
    Artwork artwork({String? pageId, bool hasPhoto = false}) => Artwork(
          id: 'a',
          pageId: pageId,
          hasPhoto: hasPhoto,
          width: 2048,
          height: 1536,
          updatedAt: DateTime(2026),
          dirPath: '/tmp/a',
        );

    test('a coloring page has an outline to go back to', () {
      expect(hasBeforeAfter(artwork(pageId: 'cat')), isTrue);
    });

    test('a painted photo has the photo to go back to', () {
      expect(hasBeforeAfter(artwork(hasPhoto: true)), isTrue);
    });

    test('free drawing started on blank paper and is not offered it', () {
      // Wiping an empty page over a painting is a trick with nothing up its
      // sleeve — better to leave the entry out than to show a blank half.
      expect(hasBeforeAfter(artwork()), isFalse);
    });
  });
}
