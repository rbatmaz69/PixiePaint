import 'dart:ui' as ui;

/// Snapshot-based undo/redo over paint-layer images. Every stored image is
/// an independent `clone()` owned by this stack; evicted or cleared entries
/// are disposed. `null` snapshots mean "empty canvas".
///
/// The stack is bounded by **memory, not by a step count**. A snapshot of
/// the main canvas is 2048 × 1536 × 4 = 12 MB, so a plain "keep 8 steps"
/// rule quietly reserves ~200 MB once the redo side fills up — more than
/// some of the Android 7 devices this app still supports have to spare.
/// Budgeting instead keeps the ceiling the same everywhere and lets the
/// smaller two-painter canvases (6 MB each) keep more history for free.
class UndoStack {
  UndoStack({
    this.budgetBytes = 48 * 1024 * 1024,
    this.minEntries = 3,
  });

  /// Ceiling for undo and redo entries combined.
  final int budgetBytes;

  /// Undo steps kept regardless of the budget. One step is not undo — a kid
  /// who fills the wrong area twice has to be able to walk back out, even on
  /// the largest canvas where three snapshots already exceed the budget.
  final int minEntries;

  final List<ui.Image?> _undo = [];
  final List<ui.Image?> _redo = [];

  int _bytes = 0;

  /// Live cost of everything held here — the number the budget is checked
  /// against, and the one tests assert on instead of trusting the rule.
  int get bytesInUse => _bytes;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// How many steps each side holds. The UI watches these to answer a tap
  /// that barely changes the picture — undoing a short stroke otherwise
  /// looks like nothing happened, and the child taps again.
  int get undoDepth => _undo.length;
  int get redoDepth => _redo.length;

  /// A blank canvas costs nothing; anything else is its raw RGBA size.
  static int _costOf(ui.Image? image) =>
      image == null ? 0 : image.width * image.height * 4;

  /// Push the pre-action state. Takes ownership of [snapshot].
  void push(ui.Image? snapshot) {
    _undo.add(snapshot);
    _bytes += _costOf(snapshot);
    _dropRedo();
    _enforceBudget();
  }

  /// Returns the snapshot to restore. Takes ownership of [current] (the
  /// state being left); the returned image is owned by the caller.
  ui.Image? undo(ui.Image? current) {
    _redo.add(current);
    _bytes += _costOf(current);
    final restored = _undo.removeLast();
    _bytes -= _costOf(restored);
    // No budget check here: the totals only moved between the two lists.
    return restored;
  }

  ui.Image? redo(ui.Image? current) {
    _undo.add(current);
    _bytes += _costOf(current);
    final restored = _redo.removeLast();
    _bytes -= _costOf(restored);
    _enforceBudget();
    return restored;
  }

  /// Hands back everything the history can spare — called when the app goes
  /// to the background, where holding 50 MB is what gets a process killed.
  /// The picture itself is already saved by then; only the ability to step
  /// back through it gets shorter.
  void trimToMinimum() {
    _dropRedo();
    while (_undo.length > 1) {
      _disposeAt(_undo.removeAt(0));
    }
  }

  void dispose() {
    for (final img in [..._undo, ..._redo]) {
      img?.dispose();
    }
    _undo.clear();
    _redo.clear();
    _bytes = 0;
  }

  /// Evicts the oldest undo entries until the budget holds — but never
  /// below [minEntries], so the guarantee above survives a canvas whose
  /// snapshots are individually larger than the whole budget.
  void _enforceBudget() {
    while (_bytes > budgetBytes && _undo.length > minEntries) {
      _disposeAt(_undo.removeAt(0));
    }
  }

  void _dropRedo() {
    for (final img in _redo) {
      _bytes -= _costOf(img);
      img?.dispose();
    }
    _redo.clear();
  }

  void _disposeAt(ui.Image? image) {
    _bytes -= _costOf(image);
    image?.dispose();
  }
}
