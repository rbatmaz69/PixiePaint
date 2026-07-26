import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/undo_stack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A real image of the given size — the stack budgets by pixel count, so
  /// null layers (which cost nothing) cannot exercise that at all.
  ui.Image image(int w, int h) {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xFF00FF00), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final img = picture.toImageSync(w, h);
    picture.dispose();
    return img;
  }

  const mb = 1024 * 1024;

  /// A 512×512 canvas, so one full-canvas patch is exactly 1 MB and the
  /// arithmetic below stays readable.
  const side = 512;
  ui.Image canvas() => image(side, side);
  ui.Rect whole() => const ui.Rect.fromLTWH(0, 0, 512, 512);

  UndoStack stackOf({int budget = 48 * mb, int min = 3}) =>
      UndoStack(width: side, height: side, budgetBytes: budget, minEntries: min);

  group('UndoStack', () {
    test('starts empty', () {
      final stack = stackOf();
      expect(stack.canUndo, false);
      expect(stack.canRedo, false);
      expect(stack.bytesInUse, 0);
    });

    test('push enables undo, undo enables redo', () {
      final stack = stackOf();
      stack.push(null, whole());
      expect(stack.canUndo, true);
      stack.undo(null);
      expect(stack.canUndo, false);
      expect(stack.canRedo, true);
      stack.redo(null);
      expect(stack.canUndo, true);
      expect(stack.canRedo, false);
    });

    test('new push clears the redo stack', () {
      final stack = stackOf();
      stack.push(null, whole());
      stack.undo(null);
      expect(stack.canRedo, true);
      stack.push(null, whole());
      expect(stack.canRedo, false);
    });
  });

  group('memory budget', () {
    test('a step costs its rect, not the canvas', () {
      // The whole point of patches: a stroke in one corner must not cost
      // what a stroke across the picture costs.
      final stack = stackOf();
      final layer = canvas();

      stack.push(layer, const ui.Rect.fromLTWH(0, 0, 64, 64));
      expect(stack.bytesInUse, 64 * 64 * 4);

      stack.push(layer, whole());
      expect(stack.bytesInUse, 64 * 64 * 4 + mb);

      layer.dispose();
      stack.dispose();
    });

    test('an empty canvas holds no pixels', () {
      final stack = stackOf();
      stack.push(null, whole());
      expect(stack.bytesInUse, 0);
    });

    test('push does not take the caller\'s layer', () {
      // It used to be handed a `clone()`; now it copies out what it needs,
      // and the caller keeps disposing its own image.
      final stack = stackOf();
      final layer = canvas();
      stack.push(layer, whole());
      expect(layer.debugDisposed, isFalse);
      layer.dispose();
      stack.dispose();
    });

    test('the oldest steps are evicted once the budget is exceeded', () {
      final stack = stackOf(budget: 4 * mb, min: 1);
      final layer = canvas();
      for (var i = 0; i < 10; i++) {
        stack.push(layer, whole());
      }

      expect(stack.bytesInUse, lessThanOrEqualTo(4 * mb));
      expect(stack.depth, 4);
      layer.dispose();
      stack.dispose();
    });

    test('minEntries wins against the budget', () {
      // Every patch on its own already blows the budget — the guarantee is
      // that a kid can still step back more than once.
      final stack = stackOf(budget: 1, min: 3);
      final layer = canvas();
      for (var i = 0; i < 8; i++) {
        stack.push(layer, whole());
      }

      expect(stack.depth, 3);
      layer.dispose();
      stack.dispose();
    });

    test('the redo side counts against the same budget', () {
      final stack = stackOf(budget: 100 * mb, min: 1);
      final layer = canvas();
      stack.push(layer, whole());
      stack.push(layer, whole());
      expect(stack.bytesInUse, 2 * mb);

      // Undoing moves a patch across and mints its mirror, so the cost of
      // the pair stays put.
      stack.undo(canvas())?.dispose();
      expect(stack.bytesInUse, 2 * mb);
      layer.dispose();
      stack.dispose();
    });

    test('an evicted patch is really freed', () {
      final stack = stackOf(budget: 2 * mb, min: 1);
      final layer = canvas();
      for (var i = 0; i < 5; i++) {
        stack.push(layer, whole());
      }
      expect(stack.bytesInUse, 2 * mb,
          reason: 'three of the five patches were released');
      layer.dispose();
      stack.dispose();
    });

    // The number this whole rebuild was about. On the painting canvas a
    // full-layer snapshot was 12.58 MB, so the 48 MB budget held exactly
    // three steps — a child who scribbled over their picture could walk
    // back three strokes and no further.
    test('the painting canvas keeps dozens of ordinary steps', () {
      final stack = UndoStack(width: 2048, height: 1536);
      final layer = image(2048, 1536);
      // A stroke-sized rect: a few hundred canvas pixels across.
      for (var i = 0; i < 60; i++) {
        stack.push(layer, ui.Rect.fromLTWH(i * 10.0, 0, 300, 300));
      }

      expect(stack.bytesInUse, lessThanOrEqualTo(stack.budgetBytes));
      expect(stack.depth, 60, reason: 'not one of them had to be evicted');
      layer.dispose();
      stack.dispose();
    });

    test('full-canvas steps still respect the budget', () {
      // Flood fills and clears cannot be bounded, so they still cost 12.58 MB
      // each and still get evicted.
      final stack = UndoStack(width: 2048, height: 1536);
      final layer = image(2048, 1536);
      for (var i = 0; i < 30; i++) {
        stack.push(layer, const ui.Rect.fromLTWH(0, 0, 2048, 1536));
      }

      expect(stack.bytesInUse, lessThanOrEqualTo(stack.budgetBytes));
      layer.dispose();
      stack.dispose();
    });
  });

  group('going to the background', () {
    // A child called away for a minute used to come back to a picture with
    // exactly one step of history, silently. And the irony of it: that one
    // step was a full 12.58 MB copy, so the whole 8 MB budget kept here now
    // is *less* memory than the old rule left behind — for dozens of steps
    // instead of one.
    test('an afternoon of ordinary strokes survives', () {
      final stack = UndoStack(width: 2048, height: 1536);
      final layer = image(2048, 1536);
      for (var i = 0; i < 40; i++) {
        stack.push(layer, ui.Rect.fromLTWH(i * 8.0, 0, 250, 250));
      }

      stack.trimToBackgroundBudget();

      expect(stack.depth, greaterThan(25));
      expect(stack.bytesInUse,
          lessThan(2048 * 1536 * 4), // one old-style snapshot
          reason: 'and it costs less than the single step it replaced');
      layer.dispose();
      stack.dispose();
    });

    test('but a history full of flood fills is given back', () {
      final stack = stackOf();
      final layer = canvas();
      for (var i = 0; i < 20; i++) {
        stack.push(layer, whole()); // 1 MB each on this canvas
      }

      stack.trimToBackgroundBudget(bytes: 4 * mb);

      expect(stack.bytesInUse, lessThanOrEqualTo(4 * mb));
      expect(stack.canUndo, isTrue, reason: 'one step back must survive');
      layer.dispose();
      stack.dispose();
    });

    test('drops the whole redo side either way', () {
      final stack = stackOf();
      final layer = canvas();
      for (var i = 0; i < 5; i++) {
        stack.push(layer, whole());
      }
      stack.undo(canvas())?.dispose();
      expect(stack.canRedo, isTrue);

      stack.trimToBackgroundBudget();

      expect(stack.canRedo, isFalse);
      layer.dispose();
      stack.dispose();
    });

    test('is safe on an empty stack', () {
      final stack = stackOf();
      stack.trimToBackgroundBudget();
      expect(stack.canUndo, isFalse);
      expect(stack.bytesInUse, 0);
    });

    test('dispose leaves nothing behind', () {
      final stack = stackOf();
      final layer = canvas();
      stack.push(layer, whole());
      stack.dispose();

      expect(stack.bytesInUse, 0);
      expect(stack.canUndo, isFalse);
      layer.dispose();
    });
  });
}
