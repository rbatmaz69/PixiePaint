import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../canvas/op_apply.dart';
import '../canvas/stroke.dart';
import '../models/draw_op.dart';
import '../util/image_io.dart';
import '../util/svg_raster.dart';

/// Drives the time-lapse: replays the recorded ops onto its own layer,
/// animating strokes point-by-point. Rendering state mirrors the live
/// canvas (committed layer + partial active stroke), and commits go through
/// the same op_apply code the canvas used — pixel-faithful by construction.
class ReplayController extends ChangeNotifier {
  ReplayController({
    required this.width,
    required this.height,
    required this.ops,
    this.background,
    this.lineArt,
  });

  final int width;
  final int height;
  final List<DrawOp> ops;

  /// Owned: disposed with the controller.
  final ui.Image? background;
  final RasterizedLineArt? lineArt;

  Uint8List? get barrierAlpha => lineArt?.barrierAlpha;

  final ValueNotifier<int> repaint = ValueNotifier<int>(0);

  ui.Image? layer;

  /// Prefix of the currently animating stroke.
  Stroke? activeStroke;
  int activeSymmetryFolds = 1;

  double speed = 2;
  bool get done => _done;
  bool _done = false;
  bool _cancelled = false;
  bool _running = false;

  /// Sticker images resolved once per replay run (path → image or null).
  final Map<String, ui.Image?> _stickers = {};

  static const _frame = Duration(milliseconds: 16);

  void cycleSpeed() {
    speed = speed >= 4 ? 1 : speed * 2;
    notifyListeners();
  }

  Future<void> play() async {
    if (_running) return;
    _running = true;
    _done = false;
    layer?.dispose();
    layer = null;
    activeStroke = null;
    _tick();
    for (final op in ops) {
      if (_cancelled) break;
      switch (op) {
        case StrokeOp():
          await _playStroke(op);
        case StampOp():
          await _playStamp(op);
        case ShapeOp():
          await _playShape(op);
        case FillOp():
          await _playFill(op);
        case ClearOp():
          layer?.dispose();
          layer = null;
          _tick();
          await _delay(const Duration(milliseconds: 350));
      }
    }
    _running = false;
    if (!_cancelled) {
      _done = true;
      notifyListeners();
    }
  }

  Future<void> _delay(Duration base) =>
      Future.delayed(base * (1 / speed));

  Stroke _strokeFrom(StrokeOp op, int pointCount) {
    final stroke = Stroke(
      kind: op.toolKind,
      color: Color(op.color),
      baseWidth: op.baseWidth,
      seed: op.seed,
    );
    for (var i = 0; i < pointCount * 3 && i + 2 < op.points.length; i += 3) {
      stroke.points.add(StrokePoint(
          ui.Offset(op.points[i], op.points[i + 1]), op.points[i + 2]));
    }
    return stroke;
  }

  Future<void> _playStroke(StrokeOp op) async {
    final total = op.points.length ~/ 3;
    if (total == 0) return;
    // Duration proportional to path length, capped — long scribbles must
    // not stall the show.
    var length = 0.0;
    for (var i = 3; i + 2 < op.points.length; i += 3) {
      final dx = op.points[i] - op.points[i - 3];
      final dy = op.points[i + 1] - op.points[i - 2];
      length += sqrt(dx * dx + dy * dy);
    }
    final durationMs = (length / 2.2).clamp(180.0, 1500.0);
    activeSymmetryFolds = op.symmetryFolds;
    final watch = Stopwatch()..start();
    var shown = 0;
    while (shown < total && !_cancelled) {
      final t =
          (watch.elapsedMilliseconds * speed / durationMs).clamp(0.0, 1.0);
      final next = max(1, (total * t).round());
      if (next != shown) {
        shown = next;
        activeStroke = _strokeFrom(op, shown);
        _tick();
      }
      if (t >= 1.0) break;
      await Future.delayed(_frame);
    }
    if (_cancelled) return;
    final newLayer = applyStroke(
      layer: layer,
      stroke: _strokeFrom(op, total),
      symmetryFolds: op.symmetryFolds,
      width: width,
      height: height,
    );
    layer?.dispose();
    layer = newLayer;
    activeStroke = null;
    _tick();
  }

  Future<ui.Image?> _stickerFor(String path) async {
    if (_stickers.containsKey(path)) return _stickers[path];
    ui.Image? image;
    try {
      final file = File(path);
      if (await file.exists()) {
        image = await pngBytesToImage(await file.readAsBytes());
      }
    } catch (_) {}
    _stickers[path] = image;
    return image;
  }

  Future<void> _playStamp(StampOp op) async {
    ui.Image? sticker;
    if (op.imagePath != null) {
      sticker = await _stickerFor(op.imagePath!);
    }
    if (_cancelled) return;
    final newLayer = applyStamp(
      layer: layer,
      // Deleted sticker file → friendly star fallback.
      emoji: sticker == null ? (op.emoji ?? '⭐') : null,
      image: sticker,
      pos: ui.Offset(op.x, op.y),
      size: op.size,
      symmetryFolds: op.symmetryFolds,
      width: width,
      height: height,
    );
    layer?.dispose();
    layer = newLayer;
    _tick();
    await _delay(const Duration(milliseconds: 400));
  }

  Future<void> _playShape(ShapeOp op) async {
    final newLayer = applyShape(
      layer: layer,
      kind: op.kind,
      center: ui.Offset(op.x, op.y),
      radius: op.radius,
      color: Color(op.color),
      strokeWidth: op.strokeWidth,
      width: width,
      height: height,
    );
    layer?.dispose();
    layer = newLayer;
    _tick();
    await _delay(const Duration(milliseconds: 400));
  }

  Future<void> _playFill(FillOp op) async {
    final newLayer = await applyFill(
      layer: layer,
      barrierAlpha: barrierAlpha,
      pos: ui.Offset(op.x, op.y),
      color: Color(op.color),
      pattern: op.pattern,
      width: width,
      height: height,
    );
    // Checked after the await, not before it: the whole fill (isolate round
    // trip plus decode) can outlive the screen.
    if (_cancelled) {
      newLayer?.dispose();
      return;
    }
    if (newLayer != null) {
      layer?.dispose();
      layer = newLayer;
      _tick();
    }
    await _delay(const Duration(milliseconds: 450));
  }

  void _tick() => repaint.value++;

  @override
  void dispose() {
    _cancelled = true;
    layer?.dispose();
    layer = null;
    background?.dispose();
    lineArt?.dispose();
    for (final img in _stickers.values) {
      img?.dispose();
    }
    _stickers.clear();
    repaint.dispose();
    super.dispose();
  }
}
