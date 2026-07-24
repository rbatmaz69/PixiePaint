@Tags(['golden'])
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/fill_pattern.dart';
import 'package:pixiepaint/canvas/op_apply.dart';
import 'package:pixiepaint/canvas/stroke.dart';
import 'package:pixiepaint/models/tool.dart';

/// Visual regression for the drawing itself — the nine pen characters, the
/// five shapes and the eight fill patterns.
///
/// **Why only these.** Golden tests over whole screens would be useless
/// here: the interface is largely emoji, and emoji render differently on
/// every machine. The drawing renderers are the opposite — pure vectors,
/// no text, and deterministic by construction: `stroke_renderer.dart` draws
/// its randomness from fixed seeds (`Random(1234)` for the crayon texture,
/// `Random(stroke.seed)` for everything else) and `shape_renderer.dart`
/// contains no randomness at all. `StrokeRenderer.drawStamp` is left out on
/// purpose — it is the one path that paints text.
///
/// This is the test that notices "the glitter pen looks different since
/// yesterday". The replay comparison in replay_test.dart cannot: it checks
/// painting against replay, and both sides would change together.
///
/// After a deliberate design change, regenerate with:
///   flutter test --update-goldens test/golden/
///
/// If *every* image fails at once right after a Flutter upgrade, suspect
/// the SDK's anti-aliasing before suspecting the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Small on purpose — the committed PNGs stay tiny and the differences
  // stay easy to look at.
  const w = 200, h = 120;

  /// A stroke across the canvas with a slight bend, so joins and tapering
  /// are visible. Pressure varies so pressure-aware pens show their range.
  Stroke strokeOf(ToolKind kind) {
    final stroke = Stroke(
      kind: kind,
      color: const Color(0xFF2E6BD6),
      baseWidth: 16,
      // Fixed: glitter and rainbow scatter from this, and a drifting seed
      // would make the golden meaningless.
      seed: 20260724,
    );
    const points = [
      (Offset(20, 90), 0.35),
      (Offset(60, 40), 0.7),
      (Offset(105, 75), 1.0),
      (Offset(150, 35), 0.6),
      (Offset(182, 80), 0.4),
    ];
    for (final (pos, pressure) in points) {
      stroke.points.add(StrokePoint(pos, pressure));
    }
    return stroke;
  }

  /// Renders onto white, so the goldens are readable rather than a
  /// transparent checkerboard.
  Future<ui.Image> onWhite(ui.Image layer) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawImage(layer, Offset.zero, Paint());
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();
    layer.dispose();
    return image;
  }

  group('pen characters', () {
    // Every ToolKind that actually draws a stroke. The others (fill, stamp,
    // shape, eyedropper) have their own paths.
    const pens = [
      ToolKind.brush,
      ToolKind.marker,
      ToolKind.crayon,
      ToolKind.rainbow,
      ToolKind.glitter,
      ToolKind.neon,
      ToolKind.trail,
      ToolKind.dotted,
      ToolKind.twin,
      ToolKind.eraser,
    ];

    for (final kind in pens) {
      testWidgets(kind.name, (tester) async {
        // The eraser only shows against something, so give it paint to cut.
        ui.Image? base;
        if (kind == ToolKind.eraser) {
          base = applyStroke(
            layer: null,
            stroke: strokeOf(ToolKind.marker),
            symmetryFolds: 1,
            width: w,
            height: h,
          );
        }
        final layer = applyStroke(
          layer: base,
          stroke: strokeOf(kind),
          symmetryFolds: 1,
          width: w,
          height: h,
        );
        base?.dispose();

        await expectLater(
          await onWhite(layer),
          matchesGoldenFile('goldens/pen_${kind.name}.png'),
        );
      });
    }

    testWidgets('mirrored four ways', (tester) async {
      final layer = applyStroke(
        layer: null,
        stroke: strokeOf(ToolKind.brush),
        symmetryFolds: 4,
        width: w,
        height: h,
      );
      await expectLater(
        await onWhite(layer),
        matchesGoldenFile('goldens/pen_brush_mirror4.png'),
      );
    });
  });

  group('shapes', () {
    for (final kind in ShapeKind.values) {
      testWidgets(kind.name, (tester) async {
        final layer = applyShape(
          layer: null,
          kind: kind,
          center: const Offset(100, 60),
          radius: 42,
          color: const Color(0xFFD6356B),
          strokeWidth: 6,
          width: w,
          height: h,
        );
        await expectLater(
          await onWhite(layer),
          matchesGoldenFile('goldens/shape_${kind.name}.png'),
        );
      });
    }
  });

  // Plain `test`, not `testWidgets`: applyFill hands the flood fill to an
  // isolate, and an isolate never finishes inside the fake-async zone that
  // testWidgets installs — the test would simply hang.
  group('fill patterns', () {
    for (final pattern in FillPattern.values) {
      test(pattern.name, () async {
        // Flooding an empty canvas fills the whole area, which is exactly
        // the sample we want of each pattern.
        final layer = await applyFill(
          layer: null,
          barrierAlpha: null,
          pos: const Offset(100, 60),
          color: const Color(0xFF35B37E),
          pattern: pattern,
          width: w,
          height: h,
        );
        expect(layer, isNotNull, reason: 'the fill produced nothing');
        await expectLater(
          await onWhite(layer!),
          matchesGoldenFile('goldens/fill_${pattern.name}.png'),
        );
      });
    }
  });
}
