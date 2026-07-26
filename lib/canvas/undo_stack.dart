import 'dart:ui' as ui;

import 'layer_patch.dart';

/// Undo/redo over the paint layer, stored as [LayerPatch] pieces: the pixels
/// an operation was about to overwrite, plus where they belong. Every stored
/// image is owned by this stack; evicted or cleared entries are disposed.
///
/// The stack is bounded by **memory, not by a step count**. Until v8.7 a
/// step was a clone of the whole layer — 2048 × 1536 × 4 = 12.58 MB — so a
/// 48 MB budget held exactly three steps on the main canvas, and a child who
/// scribbled over their picture could walk back three strokes and no
/// further. A plain "keep 8 steps" rule would instead have reserved ~200 MB
/// once the redo side filled up, more than some of the Android 7 devices
/// this app still supports have to spare.
///
/// Patches settle that: a stroke costs its own bounding box, usually a few
/// hundred kilobytes, so the same budget now carries dozens of steps and the
/// ceiling stays where it was. Operations that really do touch everything —
/// a flood fill, a symmetrical stroke, clearing the picture — still cost the
/// full 12.58 MB, and that is honest rather than guessed.
class UndoStack {
  UndoStack({
    required this.width,
    required this.height,
    this.budgetBytes = 48 * 1024 * 1024,
    this.minEntries = 3,
  });

  /// Canvas size, needed to rebuild a layer around a patch.
  final int width;
  final int height;

  /// Ceiling for undo and redo entries combined.
  final int budgetBytes;

  /// Undo steps kept regardless of the budget. One step is not undo — a kid
  /// who fills the wrong area twice has to be able to walk back out, even
  /// when three full-canvas patches already exceed the whole budget.
  final int minEntries;

  final List<LayerPatch> _undo = [];
  final List<LayerPatch> _redo = [];

  int _bytes = 0;

  /// Live cost of everything held here — the number the budget is checked
  /// against, and the one tests assert on instead of trusting the rule.
  int get bytesInUse => _bytes;

  /// How many steps back a child can actually go. Was always 3 on the main
  /// canvas before patches; worth being able to ask.
  int get depth => _undo.length;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Remembers the part of [layer] that [rect] is about to overwrite.
  ///
  /// Does **not** take ownership of [layer]: the pixels are copied out, so
  /// the caller disposes its own image as before. (The old signature took a
  /// `clone()` — with patches that clone was the expensive part and is gone.)
  void push(ui.Image? layer, ui.Rect rect) {
    _add(_undo, cropPatch(layer, clampDirtyRect(rect, width, height)));
    _dropRedo();
    _enforceBudget();
  }

  /// Steps back. Takes ownership of [current] and returns the new layer.
  ui.Image? undo(ui.Image? current) {
    final entry = _undo.removeLast();
    _bytes -= entry.bytes;
    final restored = applyPatch(
      layer: current,
      entry: entry,
      width: width,
      height: height,
    );
    // Same area, other direction — what is being left behind is what redo
    // has to put back.
    _add(_redo, _mirrorOf(entry, current));
    entry.dispose();
    current?.dispose();
    return restored;
  }

  ui.Image? redo(ui.Image? current) {
    final entry = _redo.removeLast();
    _bytes -= entry.bytes;
    final restored = applyPatch(
      layer: current,
      entry: entry,
      width: width,
      height: height,
    );
    _add(_undo, _mirrorOf(entry, current));
    entry.dispose();
    current?.dispose();
    _enforceBudget();
    return restored;
  }

  /// The state being left behind, described the same way [entry] describes
  /// the state being restored — so undo and redo are exact inverses.
  LayerPatch _mirrorOf(LayerPatch entry, ui.Image? current) {
    if (current == null) return const LayerPatch.absent();
    final rect = entry.rect;
    // Restoring "there was no layer" means the whole canvas goes; the way
    // back therefore has to carry the whole canvas.
    return cropPatch(
      current,
      rect ?? ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
  }

  /// What the history is allowed to hold while the app is in the background.
  ///
  /// Small enough not to be worth reclaiming, and — now that a step is a
  /// patch rather than a copy of the picture — large enough for a normal
  /// afternoon of drawing.
  static const int backgroundBudgetBytes = 8 * 1024 * 1024;

  /// Hands back the memory the history can spare — called when the app goes
  /// to the background, which is when Android decides which process to
  /// reclaim. The picture itself is already saved by then.
  ///
  /// This used to cut down to a single step, because a step was 12.58 MB and
  /// five of them were reason enough to kill the process. A child who gets
  /// called away for a minute, or whose parent takes a phone call, would
  /// come back to a picture they could no longer walk back through — and
  /// nothing said so. Patches are small, so trimming to a budget keeps the
  /// history intact in every ordinary case and still gives back anything
  /// that was genuinely large.
  void trimToBackgroundBudget({int bytes = backgroundBudgetBytes}) {
    _dropRedo();
    while (_bytes > bytes && _undo.length > 1) {
      _disposeAt(_undo.removeAt(0));
    }
  }

  void dispose() {
    for (final entry in [..._undo, ..._redo]) {
      entry.dispose();
    }
    _undo.clear();
    _redo.clear();
    _bytes = 0;
  }

  void _add(List<LayerPatch> into, LayerPatch entry) {
    into.add(entry);
    _bytes += entry.bytes;
  }

  /// Evicts the oldest undo entries until the budget holds — but never below
  /// [minEntries], so the guarantee above survives a run of full-canvas
  /// patches that individually rival the whole budget.
  void _enforceBudget() {
    while (_bytes > budgetBytes && _undo.length > minEntries) {
      _disposeAt(_undo.removeAt(0));
    }
  }

  void _dropRedo() {
    for (final entry in _redo) {
      _bytes -= entry.bytes;
      entry.dispose();
    }
    _redo.clear();
  }

  void _disposeAt(LayerPatch entry) {
    _bytes -= entry.bytes;
    entry.dispose();
  }
}
