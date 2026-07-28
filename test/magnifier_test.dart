import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/canvas/magnifier.dart';
import 'package:pixiepaint/util/settings.dart';

/// The lens has one job — show the spot the hand is covering — and exactly
/// two ways to fail at it: creeping over that spot, or hanging off the paper.
/// Both are geometry, so both are testable without a screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canvas = Size(2048, 1536);
  final radius = magnifierRadius(canvas.width);

  test('sits above the finger, clear of it', () {
    const pos = Offset(1000, 900);
    final center = magnifierCenter(pos: pos, canvas: canvas, radius: radius);
    expect(center.dy, lessThan(pos.dy));
    // The whole bubble is above the fingertip, not just its middle.
    expect(center.dy + radius, lessThan(pos.dy));
    expect(center.dx, pos.dx);
  });

  test('flips below the finger near the top edge', () {
    const pos = Offset(1000, 40);
    final center = magnifierCenter(pos: pos, canvas: canvas, radius: radius);
    expect(center.dy, greaterThan(pos.dy));
    expect(center.dy - radius, greaterThan(pos.dy));
  });

  test('stays fully on the paper at every corner', () {
    for (final pos in const [
      Offset(0, 0),
      Offset(2048, 0),
      Offset(0, 1536),
      Offset(2048, 1536),
      Offset(2048, 800),
    ]) {
      final center = magnifierCenter(pos: pos, canvas: canvas, radius: radius);
      expect(center.dx - radius, greaterThanOrEqualTo(0));
      expect(center.dy - radius, greaterThanOrEqualTo(0));
      expect(center.dx + radius, lessThanOrEqualTo(canvas.width));
      expect(center.dy + radius, lessThanOrEqualTo(canvas.height));
    }
  });

  test('covers the same share of the paper on both canvas sizes', () {
    // The app draws at 2048 and at 1024 wide; a lens fixed in pixels would
    // be a porthole on one of them.
    expect(magnifierRadius(1024) * 2, magnifierRadius(2048));
  });

  group('on the canvas', () {
    const w = 512;
    const h = 384;
    late CanvasController c;

    setUp(() {
      Settings.instance.resetForTest();
      c = CanvasController(canvasWidth: w, canvasHeight: h);
    });
    tearDown(() => c.dispose());

    /// A finger down and moving, without lifting.
    void fingerDown(Offset p) {
      c.pointerDown(PointerDownEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: p));
      c.pointerMove(PointerMoveEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: p + const Offset(20, 0)));
    }

    /// Alpha of the lens layer at [p], 0–255.
    Future<int> alphaAt(Offset p) async {
      final recorder = ui.PictureRecorder();
      MagnifierPainter(c).paint(
          Canvas(recorder, const Rect.fromLTWH(0, 0, 512, 384)),
          const Size(512, 384));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(w, h);
      picture.dispose();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      final i = (p.dy.floor() * w + p.dx.floor()) * 4;
      return data!.buffer.asUint8List()[i + 3];
    }

    test('paints a lens where the finger is, and nothing where it is not',
        () async {
      fingerDown(const Offset(200, 300));
      final center = magnifierCenter(
          pos: const Offset(220, 300),
          canvas: const Size(512, 384),
          radius: magnifierRadius(512));
      expect(await alphaAt(center), 255);
      // A corner far from the bubble stays untouched — the overlay is a
      // bubble, not a second full-screen layer.
      expect(await alphaAt(const Offset(4, 4)), 0);
    });

    test('draws nothing at all when a parent switched it off', () async {
      await Settings.instance.update(magnifier: false);
      fingerDown(const Offset(200, 300));
      final center = magnifierCenter(
          pos: const Offset(220, 300),
          canvas: const Size(512, 384),
          radius: magnifierRadius(512));
      expect(await alphaAt(center), 0);
    });

    test('lets go the moment the finger does', () async {
      fingerDown(const Offset(200, 300));
      c.pointerUp(PointerUpEvent(
          pointer: 1,
          kind: PointerDeviceKind.touch,
          position: const Offset(220, 300)));
      expect(c.livePoint, isNull);
    });
  });
}
