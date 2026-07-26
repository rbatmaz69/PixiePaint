import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/canvas/layer_patch.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/util/settings.dart';

/// Undo stores the piece of the picture an operation was about to overwrite
/// instead of a copy of the whole thing. That is worth dozens of steps of
/// history — and it has exactly one way to go wrong: a dirty rect that comes
/// out a little too small leaves a seam of stale pixels behind, in a corner
/// nobody thinks to look at.
///
/// So every tool is undone twice here: once through the patch the app
/// actually uses, and once by restoring a full copy of the layer taken
/// beforehand. The two results have to be the same picture, pixel for pixel.
/// The device cannot check this; this test can.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 512;
  const h = 384;

  late CanvasController c;

  setUp(() {
    Settings.instance.resetForTest();
    c = CanvasController(canvasWidth: w, canvasHeight: h);
  });
  tearDown(() => c.dispose());

  // --- pointer helpers -----------------------------------------------------

  PointerDownEvent down(Offset p) =>
      PointerDownEvent(pointer: 1, kind: PointerDeviceKind.touch, position: p);
  PointerMoveEvent move(Offset p) =>
      PointerMoveEvent(pointer: 1, kind: PointerDeviceKind.touch, position: p);
  PointerUpEvent up(Offset p) =>
      PointerUpEvent(pointer: 1, kind: PointerDeviceKind.touch, position: p);

  void stroke(Offset from, Offset to) {
    c.pointerDown(down(from));
    c.pointerMove(move(Offset.lerp(from, to, 0.5)!));
    c.pointerMove(move(to));
    c.pointerUp(up(to));
  }

  // --- pixel comparison ----------------------------------------------------

  Future<Uint8List> pixels(ui.Image? image) async {
    if (image == null) return Uint8List(0);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return data!.buffer.asUint8List();
  }

  /// Where the two images first differ, or null. Reported as a coordinate,
  /// because "byte 418 923 differs" says nothing about which corner was
  /// missed.
  ({int x, int y})? firstDifference(Uint8List a, Uint8List b) {
    if (a.length != b.length) return (x: -1, y: -1);
    for (var i = 0; i < a.length; i += 4) {
      if (a[i] != b[i] ||
          a[i + 1] != b[i + 1] ||
          a[i + 2] != b[i + 2] ||
          a[i + 3] != b[i + 3]) {
        final px = i ~/ 4;
        return (x: px % w, y: px ~/ w);
      }
    }
    return null;
  }

  /// Runs [paint] on a canvas that already holds some paint, then undoes it
  /// both ways and compares.
  Future<void> expectPatchUndoMatchesFullUndo(
    String what,
    void Function() paint,
  ) async {
    // Something underneath, so a too-small rect has stale pixels to leave
    // behind rather than transparency that happens to match.
    c.selectColor(const Color(0xFF2196F3));
    c.brushSize = 40;
    stroke(const Offset(20, 20), const Offset(w - 20.0, h - 20.0));
    stroke(const Offset(20, h - 20.0), const Offset(w - 20.0, 20));

    final before = await pixels(c.paintLayer);

    paint();
    expect(c.canUndo, isTrue, reason: '$what must be undoable at all');
    final painted = await pixels(c.paintLayer);
    expect(firstDifference(before, painted), isNotNull,
        reason: '$what did not change the picture, so the test proves nothing');

    c.undo();
    final afterUndo = await pixels(c.paintLayer);

    final diff = firstDifference(before, afterUndo);
    expect(diff, isNull,
        reason: '$what: undo left the picture different at '
            '(${diff?.x}, ${diff?.y}) — the dirty rect is too small');

    // And forward again, so the patch works in both directions.
    c.redo();
    final afterRedo = await pixels(c.paintLayer);
    final redoDiff = firstDifference(painted, afterRedo);
    expect(redoDiff, isNull,
        reason: '$what: redo did not restore it at '
            '(${redoDiff?.x}, ${redoDiff?.y})');
  }

  group('a patch undoes exactly what a full copy would', () {
    test('brush stroke', () async {
      await expectPatchUndoMatchesFullUndo('brush', () {
        c.selectColor(const Color(0xFFE53935));
        c.brushSize = 30;
        stroke(const Offset(100, 100), const Offset(300, 200));
      });
    });

    test('a stroke that runs off the edge', () async {
      await expectPatchUndoMatchesFullUndo('edge stroke', () {
        c.selectColor(const Color(0xFF43A047));
        c.brushSize = 50;
        stroke(const Offset(0, 0), const Offset(60, 5));
      });
    });

    test('a single-point tap', () async {
      await expectPatchUndoMatchesFullUndo('dot', () {
        c.selectColor(const Color(0xFF5E35B1));
        c.brushSize = 24;
        c.pointerDown(down(const Offset(250, 190)));
        c.pointerUp(up(const Offset(250, 190)));
      });
    });

    // Neon and glitter paint past the nominal stroke width; if the inflation
    // in _strokeDirtyRect were tuned to the width alone, this is the test
    // that would fail.
    for (final kind in [
      ToolKind.neon,
      ToolKind.glitter,
      ToolKind.crayon,
      ToolKind.marker,
      ToolKind.rainbow,
      ToolKind.trail,
      ToolKind.dotted,
      ToolKind.twin,
    ]) {
      test('${kind.name} stroke', () async {
        await expectPatchUndoMatchesFullUndo(kind.name, () {
          c.selectTool(kind);
          c.brushSize = 28;
          stroke(const Offset(120, 120), const Offset(320, 240));
        });
      });
    }

    test('eraser stroke', () async {
      await expectPatchUndoMatchesFullUndo('eraser', () {
        c.selectTool(ToolKind.eraser);
        c.brushSize = 60;
        stroke(const Offset(150, 100), const Offset(350, 260));
      });
    });

    test('a stroke with the magic mirror on', () async {
      await expectPatchUndoMatchesFullUndo('mirrored stroke', () {
        c.selectSymmetry(4);
        c.selectColor(const Color(0xFFFFC107));
        c.brushSize = 24;
        stroke(const Offset(80, 60), const Offset(200, 150));
      });
    });

    test('shape', () async {
      await expectPatchUndoMatchesFullUndo('shape', () {
        c.selectTool(ToolKind.shape);
        c.selectColor(const Color(0xFFEC407A));
        c.pointerDown(down(const Offset(250, 190)));
        c.pointerMove(move(const Offset(330, 260)));
        c.pointerUp(up(const Offset(330, 260)));
      });
    });

    test('sticker', () async {
      await expectPatchUndoMatchesFullUndo('stamp', () {
        c.selectTool(ToolKind.stamp);
        c.brushSize = 40;
        c.pointerDown(down(const Offset(200, 150)));
        c.pointerUp(up(const Offset(200, 150)));
      });
    });

    test('clearing the picture', () async {
      await expectPatchUndoMatchesFullUndo('clear', () => c.clearAll());
    });
  });

  group('an empty canvas is restored as empty', () {
    // `paintLayer == null` is what the whole app asks to decide whether
    // there is anything to save. A transparent image would answer wrong.
    test('undoing the very first stroke gives back no layer at all', () {
      expect(c.paintLayer, isNull);
      stroke(const Offset(50, 50), const Offset(150, 120));
      expect(c.paintLayer, isNotNull);

      c.undo();

      expect(c.paintLayer, isNull, reason: 'not a transparent image');
      expect(c.isEmpty, isTrue);
    });

    test('and redo brings the stroke back', () async {
      stroke(const Offset(50, 50), const Offset(150, 120));
      final painted = await pixels(c.paintLayer);
      c.undo();
      c.redo();

      expect(c.paintLayer, isNotNull);
      expect(firstDifference(painted, await pixels(c.paintLayer)), isNull);
    });
  });

  group('clampDirtyRect', () {
    test('grows to whole pixels instead of shrinking', () {
      final r = clampDirtyRect(const ui.Rect.fromLTRB(10.4, 10.6, 20.1, 20.9),
          100, 100);
      expect(r, const ui.Rect.fromLTRB(10, 10, 21, 21));
    });

    test('is clipped to the canvas', () {
      final r = clampDirtyRect(
          const ui.Rect.fromLTRB(-50, -50, 500, 500), 100, 80);
      expect(r, const ui.Rect.fromLTRB(0, 0, 100, 80));
    });

    test('an entirely off-canvas rect stays valid', () {
      final r =
          clampDirtyRect(const ui.Rect.fromLTRB(-90, -90, -50, -50), 100, 100);
      expect(r.width, greaterThanOrEqualTo(0));
      expect(r.height, greaterThanOrEqualTo(0));
    });
  });
}
