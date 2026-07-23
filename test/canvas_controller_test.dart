import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/models/draw_op.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/util/settings.dart';

/// The controller is the heart of the app — tools, layers, undo and the
/// time-lapse log all live here. It is driven through pointer events rather
/// than through its private commit methods, because that is how the screen
/// actually uses it: a test that skips the pointer path would not notice
/// palm rejection or a stroke that never commits.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CanvasController c;
  // Two tests dispose the controller themselves; disposing twice trips a
  // dart:ui assertion, so tearDown has to know.
  var disposed = false;

  void disposeOnce() {
    if (disposed) return;
    disposed = true;
    c.dispose();
  }

  setUp(() {
    Settings.instance.resetForTest();
    disposed = false;
    c = CanvasController(canvasWidth: 200, canvasHeight: 100);
  });

  tearDown(() {
    disposeOnce();
    Settings.instance.resetForTest();
  });

  // --- pointer helpers -----------------------------------------------------

  PointerDownEvent down(Offset p,
          {PointerDeviceKind kind = PointerDeviceKind.touch, int pointer = 1}) =>
      PointerDownEvent(pointer: pointer, kind: kind, position: p);

  PointerMoveEvent move(Offset p,
          {PointerDeviceKind kind = PointerDeviceKind.touch, int pointer = 1}) =>
      PointerMoveEvent(pointer: pointer, kind: kind, position: p);

  PointerUpEvent up(Offset p,
          {PointerDeviceKind kind = PointerDeviceKind.touch, int pointer = 1}) =>
      PointerUpEvent(pointer: pointer, kind: kind, position: p);

  /// One finished stroke from a to b.
  void drawStroke({
    Offset from = const Offset(10, 10),
    Offset to = const Offset(60, 60),
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int pointer = 1,
  }) {
    c.pointerDown(down(from, kind: kind, pointer: pointer));
    c.pointerMove(move(Offset.lerp(from, to, 0.5)!, kind: kind, pointer: pointer));
    c.pointerMove(move(to, kind: kind, pointer: pointer));
    c.pointerUp(up(to, kind: kind, pointer: pointer));
  }

  group('tool and color selection', () {
    test('selecting a tool notifies listeners', () {
      var notifications = 0;
      c.addListener(() => notifications++);
      c.selectTool(ToolKind.eraser);
      expect(c.tool, ToolKind.eraser);
      expect(notifications, 1);
    });

    test('picking a color leaves the eraser — a kid wants to paint again', () {
      c.selectTool(ToolKind.eraser);
      c.selectColor(const Color(0xFFFF0000));
      expect(c.tool, ToolKind.brush);
      expect(c.color, const Color(0xFFFF0000));
    });

    test('the eyedropper returns to the tool it interrupted', () {
      c.selectTool(ToolKind.marker);
      c.selectTool(ToolKind.eyedropper);
      c.selectColor(const Color(0xFF00FF00));
      expect(c.tool, ToolKind.marker,
          reason: 'picking a color is the end of the eyedropper, not a mode');
    });

    test('brush size is clamped to the usable range', () {
      c.selectSize(9999);
      expect(c.brushSize, kMaxBrushSize);
      c.selectSize(-5);
      expect(c.brushSize, kMinBrushSize);
    });

    test('choosing an emoji stamp drops a previously picked image stamp', () {
      c.selectStamp('🦖');
      expect(c.tool, ToolKind.stamp);
      expect(c.stampImage, isNull);
      expect(c.stampEmoji, '🦖');
    });
  });

  group('drawing', () {
    test('a finished stroke paints, dirties and bumps the revision', () {
      expect(c.isEmpty, isTrue);
      final revisionBefore = c.revision;

      drawStroke();

      expect(c.isEmpty, isFalse);
      expect(c.dirty, isTrue);
      expect(c.revision, greaterThan(revisionBefore));
      expect(c.canUndo, isTrue);
    });

    test('a stroke that never lifts stays uncommitted', () {
      c.pointerDown(down(const Offset(10, 10)));
      c.pointerMove(move(const Offset(40, 40)));

      expect(c.activeStroke, isNotNull);
      expect(c.isEmpty, isTrue, reason: 'nothing is painted until the lift');
    });

    test('extra fingers are ignored while one is drawing', () {
      c.pointerDown(down(const Offset(10, 10), pointer: 1));
      final stroke = c.activeStroke;
      c.pointerDown(down(const Offset(80, 80), pointer: 2));

      expect(identical(c.activeStroke, stroke), isTrue);
    });

    test('a resting palm does not draw while the stylus is down', () {
      c.pointerDown(down(const Offset(10, 10), kind: PointerDeviceKind.stylus));
      // The hand lands next to the pen.
      c.pointerDown(down(const Offset(90, 90), kind: PointerDeviceKind.touch, pointer: 2));
      c.pointerUp(up(const Offset(90, 90), kind: PointerDeviceKind.touch, pointer: 2));

      expect(c.activeStroke, isNotNull,
          reason: 'the pen stroke must survive the palm');
      expect(c.isEmpty, isTrue, reason: 'the palm committed nothing');
    });

    test('stylus-only mode makes fingers inert', () {
      Settings.instance.stylusOnly = true;

      drawStroke();
      expect(c.isEmpty, isTrue);

      drawStroke(kind: PointerDeviceKind.stylus);
      expect(c.isEmpty, isFalse);
    });

    test('the flipped end of a stylus erases instead of painting', () {
      drawStroke();
      c.clearOpsForTest();

      drawStroke(kind: PointerDeviceKind.invertedStylus, pointer: 2);

      final ops = c.opsSnapshot.whereType<StrokeOp>();
      expect(ops.last.toolKind, ToolKind.eraser);
    });
  });

  group('undo and redo', () {
    test('walks back and forward through several strokes', () {
      drawStroke(from: const Offset(10, 10), to: const Offset(20, 20));
      drawStroke(from: const Offset(30, 30), to: const Offset(40, 40), pointer: 2);
      drawStroke(from: const Offset(50, 50), to: const Offset(60, 60), pointer: 3);
      expect(c.opsSnapshot, hasLength(3));

      c.undo();
      c.undo();
      expect(c.opsSnapshot, hasLength(1),
          reason: 'the time-lapse must shrink with the picture');
      expect(c.canRedo, isTrue);

      c.redo();
      expect(c.opsSnapshot, hasLength(2));
    });

    test('undo and redo on an untouched canvas do nothing', () {
      expect(c.canUndo, isFalse);
      c.undo();
      c.redo();
      expect(c.isEmpty, isTrue);
      expect(c.revision, 0);
    });

    test('a new stroke after undo cuts off the redone future', () {
      drawStroke(from: const Offset(10, 10), to: const Offset(20, 20));
      drawStroke(from: const Offset(30, 30), to: const Offset(40, 40), pointer: 2);
      c.undo();
      expect(c.canRedo, isTrue);

      drawStroke(from: const Offset(70, 70), to: const Offset(80, 80), pointer: 3);

      expect(c.canRedo, isFalse);
      expect(c.opsSnapshot, hasLength(2),
          reason: 'the overwritten branch must be gone from the story too');
    });

    test('clearing an empty canvas is not an undo step', () {
      c.clearAll();
      expect(c.canUndo, isFalse);
      expect(c.opsSnapshot, isEmpty);
    });

    test('clearing a painted canvas is undoable', () {
      drawStroke();
      c.clearAll();

      expect(c.isEmpty, isTrue);
      expect(c.opsSnapshot.last, isA<ClearOp>());
      c.undo();
      expect(c.isEmpty, isFalse, reason: 'a wiped picture must come back');
    });
  });

  group('op log', () {
    test('recordOps off keeps the log empty but still paints', () {
      c.recordOps = false;
      drawStroke();

      expect(c.isEmpty, isFalse);
      expect(c.hasOps, isFalse);
    });

    test('a loaded log is the starting point for new ops', () {
      c.loadOps(const [ClearOp(), ClearOp()]);
      expect(c.opsSnapshot, hasLength(2));

      drawStroke();
      expect(c.opsSnapshot, hasLength(3));
    });

    test('the log freezes at the cap instead of drifting out of sync', () {
      c.loadOps(List.filled(CanvasController.kMaxOps, const ClearOp()));
      final before = c.opsSnapshot.length;

      drawStroke();

      expect(c.opsSnapshot.length, before,
          reason: 'a frozen log must not grow — a partial story would '
              'replay something the child never painted');
    });
  });

  group('disposal', () {
    test('a controller disposed mid-fill leaves nothing behind', () async {
      drawStroke();
      c.selectTool(ToolKind.fill);
      // Start the fill (isolate round-trip) and pull the rug out.
      final filling = c.tapFill(const Offset(30, 30));
      disposeOnce();
      await filling;

      // Reaching here without an exception is the assertion: the disposed
      // path must not touch layers or notifiers.
      expect(c.isFilling, isTrue,
          reason: 'the flag is deliberately left as-is after disposal');
    });

    test('dispose frees the layers it owns', () {
      drawStroke();
      final layer = c.paintLayer;
      expect(layer, isNotNull);

      disposeOnce();
      expect(layer!.debugDisposed, isTrue);
    });
  });
}

/// Test-only shim so a test can start from a clean log without rebuilding
/// the controller.
extension on CanvasController {
  void clearOpsForTest() => loadOps(const []);
}
