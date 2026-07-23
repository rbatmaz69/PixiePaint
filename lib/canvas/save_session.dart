import 'dart:typed_data';

import '../gallery/artwork_store.dart';
import '../models/draw_op.dart';
import '../util/image_io.dart';
import '../util/profiles.dart';
import '../util/progress.dart';
import 'canvas_controller.dart';

/// Everything the painting screen needs to know about saving, free of
/// widgets and `BuildContext` — which is what makes it testable.
///
/// The screen keeps the dialogs; this keeps the rules:
/// * three callers can ask for a save at once (the 30 s timer, the
///   lifecycle hook and leaving the screen), and they must never write the
///   same files at the same time;
/// * a picture that fails to save stays dirty so the next attempt retries,
///   and the failure is remembered for the way out — silently losing a
///   child's drawing is the one thing this must never do;
/// * the photo background and the detected line art are written once, not
///   on every autosave: they never change after loading and each costs a
///   full-canvas PNG encode.
class ArtworkSaveSession {
  ArtworkSaveSession({
    required this.controller,
    required this.artworkId,
    required this.width,
    required this.height,
    required this.hasPhoto,
    required this.hasPhotoLineArt,
    required this.cbnFilled,
    this.pageId,
    this.traceId,
    this.sceneId,
    bool resumed = false,
  })  : _everSaved = resumed,
        // A resumed artwork already has these on disk.
        _backgroundSaved = resumed && hasPhoto,
        _lineArtSaved = resumed && hasPhotoLineArt;

  final CanvasController controller;
  final String artworkId;
  final int width;
  final int height;
  final bool hasPhoto;
  final bool hasPhotoLineArt;
  final String? pageId;
  final String? traceId;
  final String? sceneId;

  /// Read at save time, because a color-by-number page keeps filling
  /// regions while the session is alive.
  final List<int> Function() cbnFilled;

  bool _everSaved;
  bool _backgroundSaved;
  bool _lineArtSaved;
  bool _saveFailed = false;
  Future<void>? _pending;

  /// True once the artwork exists on disk.
  bool get everSaved => _everSaved;

  /// True when the last attempt could not be written — surfaced to the
  /// parent on the way out, never to the child mid-painting.
  bool get saveFailed => _saveFailed;

  /// The save currently in flight, if any. The screen waits for it before
  /// disposing the controller: a save still reads the layers.
  Future<void>? get pending => _pending;

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
    if (!controller.dirty && _everSaved) return;
    // Don't create junk artworks for an untouched canvas.
    if (controller.isEmpty && !_everSaved) return;
    // Snapshot the revision: strokes committed while we encode below must
    // not be marked as saved.
    final revisionAtStart = controller.revision;

    Uint8List? paintPng;
    final layer = controller.paintLayer;
    if (layer != null) paintPng = await imageToPngBytes(layer);
    Uint8List? backgroundPng;
    if (hasPhoto && !_backgroundSaved && controller.backgroundImage != null) {
      backgroundPng = await imageToPngBytes(controller.backgroundImage!);
    }
    Uint8List? lineArtPng;
    if (hasPhotoLineArt && !_lineArtSaved && controller.lineArt != null) {
      lineArtPng = await imageToPngBytes(controller.lineArt!);
    }
    final thumb = await composeArtwork(
      width: width,
      height: height,
      background: controller.backgroundImage,
      paintLayer: controller.paintLayer,
      lineArt: controller.lineArt,
      targetWidth: 360,
    );
    final thumbPng = await imageToPngBytes(thumb);
    thumb.dispose();

    final result = await ArtworkStore.save(
      id: artworkId,
      pageId: pageId,
      traceId: traceId,
      sceneId: sceneId,
      profileId: ProfileStore.instance.active.id,
      cbnFilled: cbnFilled(),
      hasPhoto: hasPhoto,
      hasPhotoLineArt: hasPhotoLineArt,
      width: width,
      height: height,
      paintPng: paintPng,
      backgroundPng: backgroundPng,
      lineArtPng: lineArtPng,
      thumbPng: thumbPng,
      opsJson: controller.recordOps && controller.hasOps
          ? encodeOps(controller.opsSnapshot)
          : null,
    );

    if (!result.ok) {
      _saveFailed = true;
      return;
    }
    _saveFailed = false;
    if (backgroundPng != null) _backgroundSaved = true;
    if (lineArtPng != null) _lineArtSaved = true;
    _everSaved = true;
    if (controller.revision == revisionAtStart) controller.dirty = false;
    // A real, saved, non-empty picture counts as "finished" for the sticker
    // rewards (autosave makes this equivalent to having painted).
    if (controller.paintLayer != null) {
      Progress.instance.registerArtworkCompleted(artworkId);
    }
  }
}
