import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/canvas/magic_wand.dart';
import 'package:pixiepaint/canvas/op_apply.dart';
import 'package:pixiepaint/canvas/stroke.dart';
import 'package:pixiepaint/models/draw_op.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/util/settings.dart';

/// The wand is the repair tool: it asks "what is this colour" where the
/// bucket asks "what is this region". That makes it powerful in exactly the
/// way that is dangerous — it reaches the whole picture — so the two rules
/// that fence it in are what most of this file is about: it never touches
/// bare paper, and it never touches a colour that is far enough away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 8;
  const h = 4;

  /// A layer of [w]x[h] pixels, opaque, all the same colour.
  Uint8List filled(int r, int g, int b, {int a = 255}) {
    final buf = Uint8List(w * h * 4);
    for (var o = 0; o < buf.length; o += 4) {
      buf[o] = (r * a / 255).round();
      buf[o + 1] = (g * a / 255).round();
      buf[o + 2] = (b * a / 255).round();
      buf[o + 3] = a;
    }
    return buf;
  }

  test('swaps the tapped colour everywhere, not just around the tap', () {
    final buf = filled(0, 0, 255);
    // Two far-apart pixels in a different colour stay behind.
    buf[0] = 255;
    buf[1] = 0;
    buf[2] = 0;
    final out = magicRecolor(
        rgba: buf,
        width: w,
        height: h,
        seedX: 4,
        seedY: 2,
        toR: 0,
        toG: 255,
        toB: 0);
    expect(out, isNotNull);
    // The far corner changed too — this is the whole point of the tool.
    final last = (w * h - 1) * 4;
    expect([out![last], out[last + 1], out[last + 2]], [0, 255, 0]);
    // The red pixel is a different colour and was left alone.
    expect([out[0], out[1], out[2]], [255, 0, 0]);
  });

  test('does nothing on bare paper', () {
    // An untouched paint layer is transparent. Without this rule a tap on
    // the background of an unfinished picture would repaint everything the
    // child had not painted yet.
    final out = magicRecolor(
        rgba: Uint8List(w * h * 4),
        width: w,
        height: h,
        seedX: 1,
        seedY: 1,
        toR: 255,
        toG: 0,
        toB: 0);
    expect(out, isNull);
  });

  test('does nothing when the colour is already the target', () {
    final out = magicRecolor(
        rgba: filled(20, 200, 120),
        width: w,
        height: h,
        seedX: 1,
        seedY: 1,
        toR: 20,
        toG: 200,
        toB: 120);
    expect(out, isNull);
  });

  test('a tap outside the paper is not a tap', () {
    final out = magicRecolor(
        rgba: filled(0, 0, 255),
        width: w,
        height: h,
        seedX: -1,
        seedY: 99,
        toR: 255,
        toG: 0,
        toB: 0);
    expect(out, isNull);
  });

  test('keeps the alpha of a half-transparent pixel', () {
    final buf = filled(255, 0, 0, a: 128);
    final out = magicRecolor(
        rgba: buf,
        width: w,
        height: h,
        seedX: 1,
        seedY: 1,
        toR: 0,
        toG: 0,
        toB: 255)!;
    expect(out[3], 128, reason: 'a soft edge has to stay soft');
    // Premultiplied: blue at half alpha is 128, not 255.
    expect(out[2], closeTo(128, 1));
    expect(out[0], 0);
  });

  test('a neighbouring shade goes along, a different colour does not', () {
    // Anti-aliasing and the fill dilation leave colours a hair off the
    // nominal one; a tolerance that only matched exactly would leave those
    // pixels behind as a rim.
    final buf = filled(200, 60, 60);
    // Slightly off (within tolerance) and clearly off (outside it).
    buf[4] = 210;
    buf[5] = 70;
    buf[6] = 70;
    buf[8] = 60;
    buf[9] = 60;
    buf[10] = 200;
    final out = magicRecolor(
        rgba: buf,
        width: w,
        height: h,
        seedX: 4,
        seedY: 2,
        toR: 0,
        toG: 0,
        toB: 0)!;
    expect([out[4], out[5], out[6]], [0, 0, 0]);
    expect([out[8], out[9], out[10]], [60, 60, 200]);
  });

  group('on a real stroke', () {
    // The unit tests above build their own buffers, which means they agree
    // with themselves about how alpha is stored. This one goes through the
    // engine: draw a stroke, recolour it, and look at what came back.
    const cw = 64;
    const ch = 64;

    Future<Uint8List> bytesOf(ui.Image image) async {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return data!.buffer.asUint8List();
    }

    test('leaves no rim of the old colour behind', () async {
      final stroke = Stroke(
        kind: ToolKind.brush,
        color: const Color(0xFFFF0000),
        baseWidth: 12,
        seed: 1,
      )
        ..points.add(StrokePoint(const Offset(10, 32), 0.5))
        ..points.add(StrokePoint(const Offset(54, 32), 0.5));
      final layer = applyStroke(
          layer: null,
          stroke: stroke,
          symmetryFolds: 1,
          width: cw,
          height: ch);

      final after = await applyWand(
        layer: layer,
        pos: const Offset(32, 32),
        color: const Color(0xFF0000FF),
        width: cw,
        height: ch,
      );
      expect(after, isNotNull, reason: 'the stroke is there to be recoloured');

      final bytes = await bytesOf(after!);
      // Every pixel with visible paint must now read as blue, edge pixels
      // included. A red survivor means the soft edge was missed — which on
      // the real canvas is a red halo around a blue shape.
      var painted = 0;
      for (var o = 0; o < bytes.length; o += 4) {
        final a = bytes[o + 3];
        if (a < kWandMinAlpha) continue;
        painted++;
        expect(bytes[o], lessThanOrEqualTo(bytes[o + 2]),
            reason: 'pixel $o still has more red than blue in it');
      }
      expect(painted, greaterThan(100), reason: 'the stroke did get drawn');

      layer.dispose();
      after.dispose();
    });
  });

  group('through the canvas', () {
    const cw = 64;
    const ch = 64;
    late CanvasController c;

    setUp(() {
      Settings.instance.resetForTest();
      c = CanvasController(canvasWidth: cw, canvasHeight: ch);
    });
    tearDown(() => c.dispose());

    void paintBar() {
      c.selectTool(ToolKind.brush);
      c.selectColor(const Color(0xFFFF0000));
      c.brushSize = 16;
      c.pointerDown(PointerDownEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: const Offset(8, 32)));
      c.pointerMove(PointerMoveEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: const Offset(56, 32)));
      c.pointerUp(PointerUpEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: const Offset(56, 32)));
    }

    test('a tap recolours, records one op and can be undone', () async {
      paintBar();
      final opsBefore = c.opsSnapshot.length;
      final depthBefore = c.undoDepth;

      c.selectTool(ToolKind.wand);
      c.selectColor(const Color(0xFF0000FF));
      await c.tapWand(const Offset(32, 32));

      expect(c.opsSnapshot.length, opsBefore + 1);
      expect(c.opsSnapshot.last, isA<WandOp>());
      expect(c.undoDepth, depthBefore + 1,
          reason: 'the wand is one step back, not none and not two');

      c.undo();
      // Back to red: the recolour is undone like any other operation.
      final data = await c.paintLayer!
          .toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      final mid = ((32 * cw) + 32) * 4;
      expect(bytes[mid], greaterThan(bytes[mid + 2]));
    });

    test('a tap on bare paper answers without changing anything', () async {
      paintBar();
      final opsBefore = c.opsSnapshot.length;

      c.selectTool(ToolKind.wand);
      c.selectColor(const Color(0xFF0000FF));
      // Far above the bar, where nothing has been painted.
      await c.tapWand(const Offset(32, 4));

      expect(c.opsSnapshot.length, opsBefore,
          reason: 'nothing happened, so nothing belongs in the story');
      // The "I heard you, there is nothing here" ring — the same answer the
      // bucket gives, because silence reads as a broken app.
      expect(c.missedFill.value, const Offset(32, 4));
    });
  });
}
