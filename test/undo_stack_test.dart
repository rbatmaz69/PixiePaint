import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/undo_stack.dart';

// ui.Image instances need a GPU context, so these tests exercise the stack
// logic with null snapshots ("empty canvas"), which the stack supports.
void main() {
  group('UndoStack', () {
    test('starts empty', () {
      final stack = UndoStack();
      expect(stack.canUndo, false);
      expect(stack.canRedo, false);
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

    test('capacity is capped', () {
      final stack = UndoStack(capacity: 3);
      for (var i = 0; i < 10; i++) {
        stack.push(null);
      }
      var undos = 0;
      while (stack.canUndo) {
        stack.undo(null);
        undos++;
      }
      expect(undos, 3);
    });
  });
}
