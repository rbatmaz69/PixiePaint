import '../gallery/artwork_store.dart';
import '../util/image_io.dart';
import '../util/profiles.dart';
import 'canvas_controller.dart';

/// Saving for the two-painter mode, free of widgets — the sibling of
/// [ArtworkSaveSession] for the shared canvas.
///
/// Until v7.2 this mode wrote its picture *only* when someone deliberately
/// left the screen, and it minted a fresh artwork id inside that call. Two
/// consequences, both fixed here:
/// * twenty minutes of two kids painting ended at the home button;
/// * an autosave built on the old code would have produced a new gallery
///   entry every thirty seconds instead of updating the one picture.
///
/// The id is therefore fixed for the lifetime of the session, and the
/// writes are queued so the timer, the lifecycle hook and leaving can never
/// write the same files at once.
class TwoPainterSaveSession {
  TwoPainterSaveSession({
    required this.left,
    required this.right,
    required this.paneWidth,
    required this.paneHeight,
    String? artworkId,
  }) : artworkId = artworkId ?? ArtworkStore.newId();

  final CanvasController left;
  final CanvasController right;
  final int paneWidth;
  final int paneHeight;

  /// Stable for the whole session — see the class comment.
  final String artworkId;

  Future<void>? _pending;

  /// The save currently in flight, if any. The screen waits for it before
  /// disposing the controllers: a save still reads both paint layers.
  Future<void>? get pending => _pending;

  bool get isDirty => left.dirty || right.dirty;

  /// Two blank halves are not a picture.
  bool get isEmpty => left.isEmpty && right.isEmpty;

  /// Queues a save behind whatever is already running.
  Future<void> save() {
    final previous = _pending;
    final next = previous == null
        ? _saveNow()
        : previous.then((_) => _saveNow()).catchError((_) {});
    _pending = next;
    return next;
  }

  Future<void> _saveNow() async {
    if (isEmpty) return;
    try {
      final merged = await composeTwoPainterArtwork(
        left: left.paintLayer,
        right: right.paintLayer,
        paneWidth: paneWidth,
        height: paneHeight,
      );
      final paintPng = await imageToPngBytes(merged);
      final thumb = await composeArtwork(
        width: merged.width,
        height: merged.height,
        paintLayer: merged,
        targetWidth: 360,
      );
      final thumbPng = await imageToPngBytes(thumb);
      thumb.dispose();
      merged.dispose();

      final result = await ArtworkStore.save(
        id: artworkId,
        pageId: null,
        profileId: ProfileStore.instance.active.id,
        width: paneWidth * 2,
        height: paneHeight,
        paintPng: paintPng,
        thumbPng: thumbPng,
      );
      // Staying dirty on failure is what makes the next autosave retry.
      if (result.ok) {
        left.dirty = false;
        right.dirty = false;
      }
    } catch (_) {
      // Never trap the kids on the screen because a save failed.
    }
  }
}
