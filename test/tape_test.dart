import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/canvas/mask_path.dart';
import 'package:pixiepaint/canvas/op_apply.dart';
import 'package:pixiepaint/canvas/stroke.dart';
import 'package:pixiepaint/models/draw_op.dart';
import 'package:pixiepaint/models/mask.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/util/settings.dart';

/// Masking tape turns "stay inside the shape" from a motor skill into a
/// decision. That only holds if the edge is exactly where the child put it
/// and every tool respects it — so this file drags a stroke straight across
/// a piece of tape and looks at which pixels survived.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 120;
  const h = 120;
  const size = Size(120, 120);

  /// A round tape in the middle of the paper.
  const dot = Mask(kind: ShapeKind.circle, x: 60, y: 60, radius: 30);

  Stroke straightAcross() => Stroke(
        kind: ToolKind.brush,
        color: const Color(0xFFFF0000),
        baseWidth: 10,
        seed: 1,
      )
        ..points.add(StrokePoint(const Offset(4, 60), 0.5))
        ..points.add(StrokePoint(const Offset(116, 60), 0.5));

  Future<Uint8List> pixelsOf(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  }

  bool painted(Uint8List px, int x, int y) => px[(y * w + x) * 4 + 3] > 40;

  group('geometry', () {
    test('the inside of a tape is what it covers', () {
      final path = maskClipPath(dot, size);
      expect(path.contains(const Offset(60, 60)), isTrue);
      expect(path.contains(const Offset(10, 10)), isFalse);
    });

    test('turned around, it is everything but', () {
      final path = maskClipPath(
          const Mask(
              kind: ShapeKind.circle,
              x: 60,
              y: 60,
              radius: 30,
              inverted: true),
          size);
      expect(path.contains(const Offset(60, 60)), isFalse);
      expect(path.contains(const Offset(10, 10)), isTrue);
    });

    test('a strip lies along the drag, not across it', () {
      // Angle 0: the strip runs left-to-right through its centre.
      final flat = maskClipPath(
          const Mask(kind: ShapeKind.line, x: 60, y: 60, radius: 40), size);
      expect(flat.contains(const Offset(90, 60)), isTrue,
          reason: 'along the strip');
      expect(flat.contains(const Offset(60, 20)), isFalse,
          reason: 'across it, well outside');
    });

    test('an open motif falls back to something with an inside', () {
      // A rainbow is an arc. Nothing can be masked by an arc, and a tape
      // from a newer version may name anything at all.
      final path = maskClipPath(
          const Mask(kind: ShapeKind.rainbow, x: 60, y: 60, radius: 30), size);
      expect(path.contains(const Offset(60, 60)), isTrue);
    });
  });

  group('a stroke across the tape', () {
    test('only lands inside it', () async {
      final image = applyStroke(
        layer: null,
        stroke: straightAcross(),
        symmetryFolds: 1,
        width: w,
        height: h,
        mask: dot,
      );
      final px = await pixelsOf(image);
      expect(painted(px, 60, 60), isTrue, reason: 'the middle got paint');
      expect(painted(px, 10, 60), isFalse, reason: 'left of the tape');
      expect(painted(px, 110, 60), isFalse, reason: 'right of the tape');
      image.dispose();
    });

    test('turned around, it lands everywhere but', () async {
      final image = applyStroke(
        layer: null,
        stroke: straightAcross(),
        symmetryFolds: 1,
        width: w,
        height: h,
        mask: dot.copyWith(inverted: true),
      );
      final px = await pixelsOf(image);
      expect(painted(px, 60, 60), isFalse, reason: 'the tape kept it clean');
      expect(painted(px, 10, 60), isTrue);
      expect(painted(px, 110, 60), isTrue);
      image.dispose();
    });

    test('without tape it crosses the whole page', () async {
      final image = applyStroke(
        layer: null,
        stroke: straightAcross(),
        symmetryFolds: 1,
        width: w,
        height: h,
      );
      final px = await pixelsOf(image);
      expect(painted(px, 10, 60), isTrue);
      expect(painted(px, 60, 60), isTrue);
      expect(painted(px, 110, 60), isTrue);
      image.dispose();
    });
  });

  test('the eraser stops at the tape as well', () async {
    // The point of tape: rub out everything and the covered part stays.
    final painting = applyStroke(
      layer: null,
      stroke: straightAcross(),
      symmetryFolds: 1,
      width: w,
      height: h,
    );
    final rubbed = applyStroke(
      layer: painting,
      stroke: Stroke(
        kind: ToolKind.eraser,
        color: const Color(0xFF000000),
        baseWidth: 60,
        seed: 2,
      )
        ..points.add(StrokePoint(const Offset(4, 60), 0.5))
        ..points.add(StrokePoint(const Offset(116, 60), 0.5)),
      symmetryFolds: 1,
      width: w,
      height: h,
      mask: dot.copyWith(inverted: true),
    );
    final px = await pixelsOf(rubbed);
    expect(painted(px, 60, 60), isTrue, reason: 'protected by the tape');
    expect(painted(px, 10, 60), isFalse, reason: 'rubbed out');
    painting.dispose();
    rubbed.dispose();
  });

  group('the op log', () {
    test('carries the tape through a round trip', () {
      const mask = Mask(
          kind: ShapeKind.star,
          x: 12.5,
          y: 40,
          radius: 88.2,
          angle: 0.75,
          inverted: true);
      final ops = decodeOps(encodeOps([
        StrokeOp(
          toolKind: ToolKind.brush,
          color: 0xFFFF0000,
          baseWidth: 12,
          seed: 3,
          symmetryFolds: 1,
          points: [1, 2, 0.5],
          mask: mask,
        ),
      ]));
      expect((ops.single as StrokeOp).mask, mask);
    });

    test('says nothing about tape when there was none', () {
      final json = StrokeOp(
        toolKind: ToolKind.brush,
        color: 0xFFFF0000,
        baseWidth: 12,
        seed: 3,
        symmetryFolds: 1,
        points: const [1, 2, 0.5],
      ).toJson();
      expect(json.containsKey('m'), isFalse,
          reason: 'an ops.json for a picture with no tape must not grow');
    });
  });

  group('through the canvas', () {
    late CanvasController c;

    setUp(() {
      Settings.instance.resetForTest();
      c = CanvasController(canvasWidth: w, canvasHeight: h);
    });
    tearDown(() => c.dispose());

    void drag(Offset from, Offset to) {
      c.pointerDown(PointerDownEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: from));
      c.pointerMove(PointerMoveEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: to));
      c.pointerUp(PointerUpEvent(
          pointer: 1, kind: PointerDeviceKind.touch, position: to));
    }

    test('sticking tape down paints nothing and is not an undo step', () {
      c.selectTapeKind(ShapeKind.circle);
      drag(const Offset(60, 60), const Offset(90, 60));

      expect(c.tape, isNotNull);
      expect(c.isEmpty, isTrue, reason: 'tape is not paint');
      expect(c.canUndo, isFalse,
          reason: 'undo is about the picture, not about the tape');
      expect(c.opsSnapshot, isEmpty);
      // And it hands the brush back on its own: sticking tape down is a
      // preparation, never the thing a child came to do.
      expect(c.tool, ToolKind.brush);
    });

    test('a stroke drawn under tape records it', () {
      c.selectTapeKind(ShapeKind.circle);
      drag(const Offset(60, 60), const Offset(90, 60));
      drag(const Offset(4, 60), const Offset(116, 60));

      final op = c.opsSnapshot.single as StrokeOp;
      expect(op.mask, isNotNull);
      expect(op.mask!.kind, ShapeKind.circle);
    });

    test('peeling changes nothing that was painted', () async {
      c.selectTapeKind(ShapeKind.circle);
      drag(const Offset(60, 60), const Offset(90, 60));
      drag(const Offset(4, 60), const Offset(116, 60));
      final before = await pixelsOf(c.paintLayer!);

      c.peelTape();

      expect(c.tape, isNull);
      expect(await pixelsOf(c.paintLayer!), before);
    });
  });
}
