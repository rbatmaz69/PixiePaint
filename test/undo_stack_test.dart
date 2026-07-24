import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/undo_stack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A real image of the given size — the stack budgets by pixel count, so
  /// null snapshots (which cost nothing) cannot exercise that at all.
  ui.Image image(int w, int h) {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xFF00FF00), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final img = picture.toImageSync(w, h);
    picture.dispose();
    return img;
  }

  /// One megabyte's worth of pixels, give or take: 512×512×4 = 1 MB exactly.
  ui.Image oneMb() => image(512, 512);
  const mb = 1024 * 1024;

  group('UndoStack', () {
    test('starts empty', () {
      final stack = UndoStack();
      expect(stack.canUndo, false);
      expect(stack.canRedo, false);
      expect(stack.bytesInUse, 0);
    });

    test('push enables undo, undo enables redo', () {
      final stack = UndoStack();
      stack.push(null);
      expect(stack.canUndo, true);
      stack.undo(null);
      expect(stack.canUndo, false);
      expect(stack.canRedo, true);
      stack.redo(null);
      expect(stack.canUndo, true);
      expect(stack.canRedo, false);
    });

    test('new push clears the redo stack', () {
      final stack = UndoStack();
      stack.push(null);
      stack.undo(null);
      expect(stack.canRedo, true);
      stack.push(null);
      expect(stack.canRedo, false);
    });
  });

  group('memory budget', () {
    test('bytesInUse counts raw RGBA, and a blank canvas is free', () {
      final stack = UndoStack();
      stack.push(null);
      expect(stack.bytesInUse, 0, reason: 'an empty canvas holds no pixels');

      stack.push(oneMb());
      expect(stack.bytesInUse, mb);
      stack.push(image(1024, 512));
      expect(stack.bytesInUse, 3 * mb);
    });

    test('the oldest steps are evicted once the budget is exceeded', () {
      final stack = UndoStack(budgetBytes: 4 * mb, minEntries: 1);
      for (var i = 0; i < 10; i++) {
        stack.push(oneMb());
      }

      expect(stack.bytesInUse, lessThanOrEqualTo(4 * mb));
      var steps = 0;
      while (stack.canUndo) {
        stack.undo(null)?.dispose();
        steps++;
      }
      expect(steps, 4);
    });

    test('minEntries wins against the budget', () {
      // Every snapshot on its own already blows the budget — the guarantee
      // is that a kid can still step back more than once.
      final stack = UndoStack(budgetBytes: 1, minEntries: 3);
      for (var i = 0; i < 8; i++) {
        stack.push(oneMb());
      }

      var steps = 0;
      while (stack.canUndo) {
        stack.undo(null)?.dispose();
        steps++;
      }
      expect(steps, 3);
    });

    test('the redo side counts against the same budget', () {
      final stack = UndoStack(budgetBytes: 100 * mb, minEntries: 1);
      stack.push(oneMb());
      stack.push(oneMb());
      expect(stack.bytesInUse, 2 * mb);

      // Undoing moves a snapshot across, it does not create one.
      final restored = stack.undo(oneMb());
      expect(stack.bytesInUse, 2 * mb);
      restored?.dispose();
    });

    test('an evicted snapshot is really freed', () {
      final stack = UndoStack(budgetBytes: 2 * mb, minEntries: 1);
      final first = oneMb();
      stack.push(first);
      for (var i = 0; i < 4; i++) {
        stack.push(oneMb());
      }

      // Disposing an already-disposed image throws — which is exactly the
      // assertion: the stack got there first.
      expect(first.debugDisposed, isTrue);
    });

    test('the real canvas sizes stay under the default budget', () {
      // 2048×1536 is the painting canvas, 1024×1536 one two-painter pane.
      final main = UndoStack();
      for (var i = 0; i < 30; i++) {
        main.push(image(2048, 1536));
      }
      expect(main.bytesInUse, lessThanOrEqualTo(main.budgetBytes),
          reason: 'the painting canvas must respect the budget');
      main.dispose();

      final pane = UndoStack();
      for (var i = 0; i < 30; i++) {
        pane.push(image(1024, 1536));
      }
      expect(pane.bytesInUse, lessThanOrEqualTo(pane.budgetBytes));
      pane.dispose();
    });
  });

  group('trimToMinimum', () {
    test('keeps one step and drops the whole redo side', () {
      final stack = UndoStack();
      for (var i = 0; i < 5; i++) {
        stack.push(oneMb());
      }
      stack.undo(oneMb())?.dispose();
      stack.undo(oneMb())?.dispose();
      expect(stack.canRedo, isTrue);

      stack.trimToMinimum();

      expect(stack.canRedo, isFalse);
      expect(stack.canUndo, isTrue, reason: 'one step back must survive');
      expect(stack.bytesInUse, mb);
    });

    test('is safe on an empty stack', () {
      final stack = UndoStack();
      stack.trimToMinimum();
      expect(stack.canUndo, isFalse);
      expect(stack.bytesInUse, 0);
    });

    test('dispose leaves nothing behind', () {
      final stack = UndoStack();
      final held = oneMb();
      stack.push(held);
      stack.dispose();

      expect(held.debugDisposed, isTrue);
      expect(stack.bytesInUse, 0);
      expect(stack.canUndo, isFalse);
    });
  });
}
