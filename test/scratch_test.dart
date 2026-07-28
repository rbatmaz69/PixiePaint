import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/canvas/scratch.dart';
import 'package:pixiepaint/gallery/before_after_screen.dart';
import 'package:pixiepaint/models/artwork.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/util/image_io.dart';
import 'package:pixiepaint/util/settings.dart';

/// A scratch picture is built out of parts the app already had: the colours
/// go where a photo goes (which the eraser has never been able to reach) and
/// the cover is an ordinary paint layer. So what the tests have to hold down
/// is the trick itself — scratching reveals colour, and nothing a child can
/// do takes the colours away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 96;
  const h = 72;

  Future<Uint8List> pixelsOf(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  }

  ({int r, int g, int b, int a}) at(Uint8List px, int x, int y) {
    final o = (y * w + x) * 4;
    return (r: px[o], g: px[o + 1], b: px[o + 2], a: px[o + 3]);
  }

  test('the cover is opaque everywhere', () async {
    final cover = scratchCover(w, h);
    final px = await pixelsOf(cover);
    for (var i = 3; i < px.length; i += 4) {
      expect(px[i], 255, reason: 'a gap in the cover gives the trick away');
    }
    cover.dispose();
  });

  test('the cover is exactly the colour the op log records', () async {
    // The time-lapse replays the cover as a plain fill in [kScratchCover].
    // If the image and the fill ever drift apart, the film starts on a page
    // that never existed.
    final px = await pixelsOf(scratchCover(w, h));
    final pixel = at(px, w ~/ 2, h ~/ 2);
    expect(pixel.r, (kScratchCover.r * 255).round());
    expect(pixel.g, (kScratchCover.g * 255).round());
    expect(pixel.b, (kScratchCover.b * 255).round());
  });

  test('the colour sheet is opaque and actually colourful', () async {
    final sheet = scratchColourSheet(w, h, 7);
    final px = await pixelsOf(sheet);
    final hues = <double>{};
    for (var x = 4; x < w; x += 8) {
      final c = at(px, x, h ~/ 2);
      expect(c.a, 255);
      hues.add(HSLColor.fromColor(Color.fromARGB(255, c.r, c.g, c.b)).hue);
    }
    expect(hues.length, greaterThan(3),
        reason: 'a sheet of one colour is not worth scratching');
    sheet.dispose();
  });

  test('two pictures get different sheets, the same one twice does not',
      () async {
    final a = await pixelsOf(scratchColourSheet(w, h, 1));
    final b = await pixelsOf(scratchColourSheet(w, h, 2));
    final again = await pixelsOf(scratchColourSheet(w, h, 1));
    expect(a, isNot(b));
    expect(a, again, reason: 'the same picture must redraw identically');
  });

  group('scratching', () {
    late CanvasController c;

    setUp(() {
      Settings.instance.resetForTest();
      c = CanvasController(canvasWidth: w, canvasHeight: h);
      c.setBackground(scratchColourSheet(w, h, 3));
      c.setPaintLayer(scratchCover(w, h));
      c.tool = ToolKind.eraser;
    });
    tearDown(() => c.dispose());

    /// What the picture looks like from outside: colours, then whatever is
    /// left of the cover — the same order every export uses.
    Future<Uint8List> visible() async {
      final composed = await composeArtwork(
        width: w,
        height: h,
        background: c.backgroundImage,
        paintLayer: c.paintLayer,
      );
      final px = await pixelsOf(composed);
      composed.dispose();
      return px;
    }

    /// The eraser, dragged across the page — the scratching stick.
    void scratch(Offset from, Offset to) {
      c.brushSize = 20;
      c.pointerDown(PointerDownEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: from));
      c.pointerMove(PointerMoveEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: to));
      c.pointerUp(PointerUpEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: to));
    }

    test('rubbing the cover brings a colour out', () async {
      final before = at(await visible(), w ~/ 2, h ~/ 2);
      scratch(const Offset(8, 36), const Offset(88, 36));
      final after = at(await visible(), w ~/ 2, h ~/ 2);

      expect(before.r, (kScratchCover.r * 255).round(),
          reason: 'covered to start with');
      expect(after, isNot(before));
      // Something colourful, not just a lighter grey.
      final colour = Color.fromARGB(255, after.r, after.g, after.b);
      expect(HSLColor.fromColor(colour).saturation, greaterThan(0.3));
      expect(HSLColor.fromColor(colour).lightness, greaterThan(0.25));
    });

    test('scratching the same spot twice reveals no more than once',
        () async {
      scratch(const Offset(8, 36), const Offset(88, 36));
      final once = at(await visible(), w ~/ 2, h ~/ 2);
      scratch(const Offset(8, 36), const Offset(88, 36));

      // The middle of the scratch, not the whole picture: a second pass does
      // clean up the soft edge of the first one a little further, the way
      // rubbing twice would. What must not change is what is underneath —
      // the colours are the floor, and there is nothing below them.
      expect(at(await visible(), w ~/ 2, h ~/ 2), once);
    });

    test('undo puts the cover back', () async {
      final covered = await visible();
      scratch(const Offset(8, 36), const Offset(88, 36));
      expect(await visible(), isNot(covered));

      c.undo();

      expect(await visible(), covered);
    });
  });

  test('a scratch picture is not offered the before/after wipe', () {
    // Its "before" is the bare colour sheet — a page the child never saw.
    Artwork artwork({required bool scratch}) => Artwork(
          id: 'a',
          pageId: null,
          hasPhoto: true,
          scratch: scratch,
          width: 2048,
          height: 1536,
          updatedAt: DateTime(2026),
          dirPath: '/tmp/a',
        );
    expect(hasBeforeAfter(artwork(scratch: false)), isTrue);
    expect(hasBeforeAfter(artwork(scratch: true)), isFalse);
  });

  test('the flag survives a meta.json round trip', () {
    final artwork = Artwork(
      id: 'a',
      pageId: null,
      hasPhoto: true,
      scratch: true,
      width: 64,
      height: 48,
      updatedAt: DateTime(2026, 7, 28),
      dirPath: '/tmp/a',
    );
    expect(Artwork.fromJson(artwork.toJson(), '/tmp/a').scratch, isTrue);
    // And a picture that is not one stays not one.
    expect(
        Artwork.fromJson(
                artwork.copyWith().toJson()..remove('scratch'), '/tmp/a')
            .scratch,
        isFalse);
  });
}
