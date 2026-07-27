import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/fill_pattern.dart';
import 'package:pixiepaint/canvas/op_apply.dart';
import 'package:pixiepaint/canvas/stroke.dart';
import 'package:pixiepaint/models/draw_op.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/replay/replay_controller.dart';

/// The time-lapse promises one thing: what it shows is what the child
/// painted. Nothing checked that until now — `draw_op_test.dart` only
/// covers the JSON, so the replay could quietly draw something else and
/// every test would still pass.
///
/// These tests paint through `op_apply` (the path the live canvas takes),
/// replay the same ops through `ReplayController`, and compare the pixels.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 120, h = 80;

  Future<Uint32List> pixelsOf(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint32List();
  }

  /// How many pixels differ. Zero is the expectation everywhere below —
  /// both sides run the same renderers, so anything else is a real drift.
  Future<int> diff(ui.Image a, ui.Image b) async {
    final pa = await pixelsOf(a);
    final pb = await pixelsOf(b);
    expect(pa.length, pb.length);
    var differing = 0;
    for (var i = 0; i < pa.length; i++) {
      if (pa[i] != pb[i]) differing++;
    }
    return differing;
  }

  Stroke strokeOf(StrokeOp op) {
    final s = Stroke(
      kind: op.toolKind,
      color: Color(op.color),
      baseWidth: op.baseWidth,
      seed: op.seed,
    );
    for (var i = 0; i + 2 < op.points.length; i += 3) {
      s.points.add(StrokePoint(Offset(op.points[i], op.points[i + 1]),
          op.points[i + 2]));
    }
    return s;
  }

  /// Applies ops the way the painting canvas does.
  Future<ui.Image?> paint(List<DrawOp> ops) async {
    ui.Image? layer;
    for (final op in ops) {
      switch (op) {
        case StrokeOp():
          final next = applyStroke(
            layer: layer,
            stroke: strokeOf(op),
            symmetryFolds: op.symmetryFolds,
            width: w,
            height: h,
          );
          layer?.dispose();
          layer = next;
        case TextOp():
          final next = applyText(
            layer: layer,
            text: op.text,
            pos: Offset(op.x, op.y),
            size: op.size,
            color: Color(op.color),
            symmetryFolds: op.symmetryFolds,
            width: w,
            height: h,
          );
          layer?.dispose();
          layer = next;
        case StampOp():
          final next = applyStamp(
            layer: layer,
            emoji: op.emoji,
            pos: Offset(op.x, op.y),
            size: op.size,
            symmetryFolds: op.symmetryFolds,
            width: w,
            height: h,
          );
          layer?.dispose();
          layer = next;
        case ShapeOp():
          final next = applyShape(
            layer: layer,
            kind: op.kind,
            center: Offset(op.x, op.y),
            radius: op.radius,
            color: Color(op.color),
            strokeWidth: op.strokeWidth,
            angle: op.angle,
            outline: op.outline,
            width: w,
            height: h,
          );
          layer?.dispose();
          layer = next;
        case FillOp():
          final next = await applyFill(
            layer: layer,
            barrierAlpha: null,
            pos: Offset(op.x, op.y),
            color: Color(op.color),
            pattern: op.pattern,
            width: w,
            height: h,
          );
          if (next != null) {
            layer?.dispose();
            layer = next;
          }
        case ClearOp():
          layer?.dispose();
          layer = null;
      }
    }
    return layer;
  }

  /// Runs the same ops through the replay engine and returns its result.
  Future<ui.Image?> replay(List<DrawOp> ops) async {
    final controller =
        ReplayController(width: w, height: h, ops: ops);
    // Fastest setting: the animation timing is not what is under test.
    controller.speed = 4;
    await controller.play();
    // Hand the layer over before disposal takes it with the controller.
    final result = controller.layer;
    controller.layer = null;
    controller.dispose();
    return result;
  }

  StrokeOp brushStroke({
    Color color = const Color(0xFF2266DD),
    ToolKind kind = ToolKind.brush,
    int folds = 1,
    List<Offset> path = const [
      Offset(10, 10),
      Offset(40, 30),
      Offset(70, 55),
    ],
  }) =>
      StrokeOp(
        toolKind: kind,
        color: color.toARGB32(),
        baseWidth: 12,
        // A fixed seed matters: glitter and rainbow randomise from it, so a
        // replay with a different seed would look plausible but wrong.
        seed: 4242,
        symmetryFolds: folds,
        points: [for (final p in path) ...[p.dx, p.dy, 0.6]],
      );

  group('replay matches the painting', () {
    test('a single brush stroke', () async {
      final ops = [brushStroke()];
      final painted = await paint(ops);
      final replayed = await replay(ops);

      expect(painted, isNotNull);
      expect(replayed, isNotNull);
      expect(await diff(painted!, replayed!), 0);
      painted.dispose();
      replayed.dispose();
    });

    test('a stroke whose look depends on its seed', () async {
      // Glitter scatters sparkles from the seed — the strictest check that
      // the replay rebuilds the stroke rather than approximating it.
      final ops = [brushStroke(kind: ToolKind.glitter)];
      final painted = await paint(ops);
      final replayed = await replay(ops);

      expect(await diff(painted!, replayed!), 0,
          reason: 'the seed must survive the round trip');
      painted.dispose();
      replayed.dispose();
    });

    test('a mirrored stroke', () async {
      final ops = [brushStroke(folds: 4)];
      final painted = await paint(ops);
      final replayed = await replay(ops);

      expect(await diff(painted!, replayed!), 0);
      painted.dispose();
      replayed.dispose();
    });

    test('a stroke, a shape and a stamp in sequence', () async {
      final ops = <DrawOp>[
        brushStroke(),
        ShapeOp(
          kind: ShapeKind.heart,
          x: 60,
          y: 40,
          radius: 18,
          color: const Color(0xFFEE3366).toARGB32(),
          strokeWidth: 5,
        ),
        StampOp(emoji: '⭐', x: 30, y: 55, size: 24, symmetryFolds: 1),
      ];
      final painted = await paint(ops);
      final replayed = await replay(ops);

      expect(await diff(painted!, replayed!), 0);
      painted.dispose();
      replayed.dispose();
    });

    test('a word written on the picture', () async {
      // The letters tool is the one op whose payload is a string. If the
      // replay wrote a different word, a different colour or a different
      // size, this is where it would show.
      final ops = [
        TextOp(
            text: 'Mia',
            x: 60,
            y: 40,
            size: 26,
            color: 0xFF1E88E5,
            symmetryFolds: 1),
      ];
      final painted = await paint(ops);
      final replayed = await replay(ops);

      expect(await diff(painted!, replayed!), 0);
      painted.dispose();
      replayed.dispose();
    });

    test('a fill on top of a stroke', () async {
      final ops = <DrawOp>[
        brushStroke(),
        FillOp(
          x: 100,
          y: 70,
          color: const Color(0xFF33CC88).toARGB32(),
          pattern: FillPattern.solid,
        ),
      ];
      final painted = await paint(ops);
      final replayed = await replay(ops);

      expect(await diff(painted!, replayed!), 0);
      painted.dispose();
      replayed.dispose();
    });

    test('a wipe halfway through', () async {
      final ops = <DrawOp>[
        brushStroke(),
        const ClearOp(),
        brushStroke(
          color: const Color(0xFFDD8800),
          path: [Offset(20, 60), Offset(90, 20)],
        ),
      ];
      final painted = await paint(ops);
      final replayed = await replay(ops);

      expect(await diff(painted!, replayed!), 0,
          reason: 'everything before the wipe must be gone on both sides');
      painted.dispose();
      replayed.dispose();
    });
  });

  group('replay edges', () {
    test('an empty story ends immediately with a blank canvas', () async {
      final controller =
          ReplayController(width: w, height: h, ops: const []);
      await controller.play();

      expect(controller.done, isTrue);
      expect(controller.layer, isNull);
      controller.dispose();
    });

    test('a story that only wipes stays blank', () async {
      expect(await replay(const [ClearOp()]), isNull);
    });

    test('cancelling stops the show and leaves it disposable', () async {
      final controller = ReplayController(
        width: w,
        height: h,
        ops: [for (var i = 0; i < 20; i++) brushStroke()],
      );
      final running = controller.play();
      controller.dispose();
      await running;

      expect(controller.done, isFalse,
          reason: 'a cancelled replay never reports itself finished');
    });

    // The bar under the paper (v8.4). Counted in operations rather than in
    // time on purpose: a fill takes a moment and a long stroke takes
    // seconds, so a clock would visibly run uneven.
    test('the progress runs from nothing to full across the ops', () async {
      final controller = ReplayController(
        width: w,
        height: h,
        ops: [for (var i = 0; i < 4; i++) brushStroke()],
      );
      final seen = <double>[];
      controller.addListener(() => seen.add(controller.progress));

      await controller.play();

      expect(seen.first, greaterThan(0.0));
      expect(seen.last, 1.0, reason: 'die Leiste kam nicht am Ende an');
      expect(seen, orderedEquals([...seen]..sort()),
          reason: 'die Leiste lief zwischendurch rückwärts');
      controller.dispose();
    });

    test('an empty story is finished before it starts', () {
      final controller = ReplayController(width: w, height: h, ops: []);
      // Dividing by ops.length would be a NaN here, and a NaN width factor
      // is an assertion in the layout, not a quiet wrong number.
      expect(controller.progress, 1.0);
      controller.dispose();
    });

    test('replaying twice gives the same picture', () async {
      final ops = [brushStroke(kind: ToolKind.rainbow)];
      final first = await replay(ops);
      final second = await replay(ops);

      expect(await diff(first!, second!), 0);
      first.dispose();
      second.dispose();
    });
  });
}
