import 'dart:ui' as ui;

/// Snapshot-based undo/redo over paint-layer images. Every stored image is
/// an independent `clone()` owned by this stack; evicted or cleared entries
/// are disposed. `null` snapshots mean "empty canvas".
class UndoStack {
  UndoStack({this.capacity = 8});

  final int capacity;
  final List<ui.Image?> _undo = [];
  final List<ui.Image?> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Push the pre-action state. Takes ownership of [snapshot].
  void push(ui.Image? snapshot) {
    _undo.add(snapshot);
    if (_undo.length > capacity) {
      _undo.removeAt(0)?.dispose();
    }
    for (final img in _redo) {
      img?.dispose();
    }
    _redo.clear();
  }

  /// Returns the snapshot to restore. Takes ownership of [current] (the
  /// state being left); the returned image is owned by the caller.
  ui.Image? undo(ui.Image? current) {
    _redo.add(current);
    return _undo.removeLast();
  }

  ui.Image? redo(ui.Image? current) {
    _undo.add(current);
    return _redo.removeLast();
  }

  void dispose() {
    for (final img in [..._undo, ..._redo]) {
      img?.dispose();
    }
    _undo.clear();
    _redo.clear();
  }
}
