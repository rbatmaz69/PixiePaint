import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/tool.dart';
import '../util/image_io.dart';
import '../util/settings.dart';
import 'flood_fill.dart' as ff;
import 'stroke.dart';
import 'stroke_renderer.dart';
import 'undo_stack.dart';

/// Central canvas state: layers, active stroke, tools, undo/redo.
///
/// High-frequency pointer updates bypass the widget tree — the painter
/// listens to [repaint]; `notifyListeners` is only fired for toolbar-level
/// state (tool/color selection, undo availability, busy flag).
class CanvasController extends ChangeNotifier {
  CanvasController({required this.canvasWidth, required this.canvasHeight});

  final int canvasWidth;
  final int canvasHeight;

  /// Bumped every time the canvas content must repaint.
  final ValueNotifier<int> repaint = ValueNotifier<int>(0);

  ui.Image? paintLayer;
  ui.Image? lineArt;
  Uint8List? barrierAlpha;
  Stroke? activeStroke;

  ToolKind tool = ToolKind.brush;
  int sizeIndex = 1;
  Color color = const Color(0xFFE53935);

  final UndoStack _undoStack = UndoStack();
  bool get canUndo => _undoStack.canUndo;
  bool get canRedo => _undoStack.canRedo;

  bool isFilling = false;
  bool dirty = false;
  bool get isEmpty => paintLayer == null;

  int? _activePointer;
  bool _activeIsStylus = false;
  bool _stylusDown = false;
  final Random _rng = Random();

  ui.Rect get _bounds =>
      ui.Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble());

  void setLineArt(ui.Image image, Uint8List barrier) {
    lineArt?.dispose();
    lineArt = image;
    barrierAlpha = barrier;
    _tick();
  }

  void setPaintLayer(ui.Image? image) {
    paintLayer?.dispose();
    paintLayer = image;
    _tick();
  }

  void selectTool(ToolKind t) {
    tool = t;
    notifyListeners();
  }

  void selectSize(int index) {
    sizeIndex = index;
    notifyListeners();
  }

  void selectColor(Color c) {
    color = c;
    if (tool == ToolKind.eraser) tool = ToolKind.brush;
    notifyListeners();
  }

  double get _baseWidth => kBrushSizes[sizeIndex];

  // ---------------------------------------------------------------- pointer

  static const _drawingKinds = {
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };

  void pointerDown(PointerDownEvent e) {
    if (isFilling || !_drawingKinds.contains(e.kind)) return;
    final isStylus = e.kind == PointerDeviceKind.stylus ||
        e.kind == PointerDeviceKind.invertedStylus;
    final isTouch = e.kind == PointerDeviceKind.touch;

    // Palm rejection: while a stylus is on the screen (or in stylus-only
    // mode), finger touches never draw.
    if (isTouch && (_stylusDown || Settings.instance.stylusOnly)) return;
    if (isStylus) _stylusDown = true;

    if (activeStroke != null) {
      if (isStylus && !_activeIsStylus) {
        // A palm stroke started before the pen landed — discard it.
        _cancelActiveStroke();
      } else {
        return; // ignore extra fingers while drawing
      }
    }

    final pos = _clamp(e.localPosition);
    if (tool == ToolKind.fill) {
      tapFill(pos);
      return;
    }

    // Flipped stylus end = eraser, like a pencil.
    final kind = e.kind == PointerDeviceKind.invertedStylus
        ? ToolKind.eraser
        : tool;

    _activePointer = e.pointer;
    _activeIsStylus = isStylus;
    activeStroke = Stroke(
      kind: kind,
      color: color,
      baseWidth: _baseWidth,
      seed: _rng.nextInt(1 << 31),
    )..points.add(StrokePoint(pos, _pressure(e)));
    _tick();
  }

  void pointerMove(PointerMoveEvent e) {
    final stroke = activeStroke;
    if (stroke == null || e.pointer != _activePointer) return;
    final pos = _clamp(e.localPosition);
    if (stroke.points.isNotEmpty &&
        (pos - stroke.points.last.pos).distance < 1.0) {
      return;
    }
    stroke.points.add(StrokePoint(pos, _pressure(e)));
    _tick();
  }

  void pointerUp(PointerEvent e) {
    if (e.kind == PointerDeviceKind.stylus ||
        e.kind == PointerDeviceKind.invertedStylus) {
      _stylusDown = false;
    }
    if (e.pointer != _activePointer) return;
    if (e is PointerCancelEvent) {
      _cancelActiveStroke();
      return;
    }
    _commitActiveStroke();
  }

  double _pressure(PointerEvent e) {
    final range = e.pressureMax - e.pressureMin;
    if (e.kind != PointerDeviceKind.stylus || range <= 0) return 0.5;
    return ((e.pressure - e.pressureMin) / range).clamp(0.0, 1.0);
  }

  Offset _clamp(Offset p) => Offset(
        p.dx.clamp(0.0, canvasWidth.toDouble()),
        p.dy.clamp(0.0, canvasHeight.toDouble()),
      );

  void _cancelActiveStroke() {
    activeStroke = null;
    _activePointer = null;
    _activeIsStylus = false;
    _tick();
  }

  void _commitActiveStroke() {
    final stroke = activeStroke;
    if (stroke == null) return;
    activeStroke = null;
    _activePointer = null;
    _activeIsStylus = false;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, _bounds);
    final erasing = stroke.kind == ToolKind.eraser;
    if (erasing) canvas.saveLayer(_bounds, Paint());
    if (paintLayer != null) {
      canvas.drawImage(paintLayer!, Offset.zero, Paint());
    }
    StrokeRenderer.draw(canvas, stroke);
    if (erasing) canvas.restore();
    final picture = recorder.endRecording();
    final newLayer = picture.toImageSync(canvasWidth, canvasHeight);
    picture.dispose();

    _pushUndoAndReplace(newLayer);
  }

  void _pushUndoAndReplace(ui.Image? newLayer) {
    _undoStack.push(paintLayer?.clone());
    paintLayer?.dispose();
    paintLayer = newLayer;
    dirty = true;
    _tick();
    notifyListeners();
  }

  // ------------------------------------------------------------------- fill

  Future<void> tapFill(Offset pos) async {
    if (isFilling || activeStroke != null) return;
    isFilling = true;
    notifyListeners();
    try {
      final w = canvasWidth, h = canvasHeight;
      Uint8List rgba;
      if (paintLayer != null) {
        final data =
            await paintLayer!.toByteData(format: ui.ImageByteFormat.rawRgba);
        rgba = data!.buffer.asUint8List();
      } else {
        rgba = Uint8List(w * h * 4);
      }
      final barrier = barrierAlpha;
      final seedX = pos.dx.floor().clamp(0, w - 1);
      final seedY = pos.dy.floor().clamp(0, h - 1);
      final c = color;
      final result = await Isolate.run(() => ff.floodFill(
            rgba: rgba,
            barrierAlpha: barrier,
            width: w,
            height: h,
            seedX: seedX,
            seedY: seedY,
            fillR: (c.r * 255).round(),
            fillG: (c.g * 255).round(),
            fillB: (c.b * 255).round(),
            tolerance: kFillTolerance,
            // Without line art there is nothing to hide the dilation under.
            dilationPasses: barrier == null ? 0 : 3,
          ));
      if (result != null) {
        final newLayer = await rgbaToImage(result, w, h);
        _pushUndoAndReplace(newLayer);
      }
    } finally {
      isFilling = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------- undo/clear

  void undo() {
    if (!canUndo) return;
    paintLayer = _undoStack.undo(paintLayer);
    dirty = true;
    _tick();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    paintLayer = _undoStack.redo(paintLayer);
    dirty = true;
    _tick();
    notifyListeners();
  }

  void clearAll() {
    if (paintLayer == null) return;
    _pushUndoAndReplace(null);
  }

  void _tick() => repaint.value++;

  @override
  void dispose() {
    _undoStack.dispose();
    paintLayer?.dispose();
    lineArt?.dispose();
    repaint.dispose();
    super.dispose();
  }
}
