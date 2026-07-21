import 'dart:isolate';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/tool.dart';
import '../util/color_utils.dart';
import '../util/image_io.dart';
import '../util/progress.dart';
import '../util/settings.dart';
import '../util/sfx.dart';
import '../util/svg_raster.dart';
import 'fill_pattern.dart';
import 'flood_fill.dart' as ff;
import 'shape_renderer.dart';
import 'stroke.dart';
import 'stroke_renderer.dart';
import 'symmetry.dart';
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

  /// Seed position of the last successful flood fill (drives the burst
  /// animation overlay).
  final ValueNotifier<Offset?> lastFill = ValueNotifier<Offset?>(null);

  /// Position of the last committed stamp (drives the sparkle overlay).
  final ValueNotifier<Offset?> lastStamp = ValueNotifier<Offset?>(null);

  ui.Image? paintLayer;
  ui.Image? lineArt;

  /// Vector display list of the line art — drawn on screen instead of the
  /// raster so outlines stay sharp when zoomed.
  ui.Picture? lineArtPicture;
  ui.Picture? _lineArtSource;

  /// Photo background drawn under the paint layer (photo mode).
  ui.Image? backgroundImage;

  /// Tracing guide drawn under the paint layer (trace mode) — never baked
  /// into commits, thumbnails or exports.
  ui.Picture? traceGuide;

  /// Fired after each committed stroke (trace mode feeds its coverage).
  void Function(Stroke stroke)? onStrokeCommitted;

  Uint8List? barrierAlpha;
  Stroke? activeStroke;

  ToolKind tool = ToolKind.brush;
  double brushSize = 28;
  Color color = const Color(0xFFE53935);
  String stampEmoji = '⭐';

  /// A custom sticker selected as the stamp motif; when set, it wins over
  /// [stampEmoji]. At most one decoded image is held at a time.
  String? stampImagePath;
  ui.Image? stampImage;
  FillPattern fillPattern = FillPattern.solid;
  ShapeKind shapeKind = ShapeKind.heart;

  /// Magic-mirror copies per gesture (1 = off, 2/4/6 = butterfly/flower/
  /// snowflake). Applies to strokes and stamps, not fill/eyedropper/shape.
  int symmetryFolds = 1;

  /// Live position of a stamp being placed (finger still down).
  Offset? pendingStampPos;

  /// Center and current drag position of a shape being placed.
  Offset? shapeCenter;
  Offset? shapeCurrent;

  /// Live position of an eyedropper pick (finger still down) and the color
  /// currently under it — drives the loupe overlay.
  Offset? pendingPickPos;
  Color? pickedPreview;
  Uint8List? _pickBuffer;
  ToolKind _toolBeforePick = ToolKind.brush;

  final UndoStack _undoStack = UndoStack();
  bool get canUndo => _undoStack.canUndo;
  bool get canRedo => _undoStack.canRedo;

  bool isFilling = false;
  bool dirty = false;
  bool get isEmpty => paintLayer == null;

  int? _activePointer;
  bool _activeIsStylus = false;
  bool _stylusDown = false;
  bool _viewGestureActive = false;
  final Random _rng = Random();

  /// True while a stylus is touching the screen (viewport uses this to
  /// ignore pinches from a resting hand).
  bool get stylusDown => _stylusDown;

  /// Called by the viewport when a two-finger pinch starts. A half-drawn
  /// first-finger stroke is discarded (like palm rejection), never
  /// committed.
  void beginViewGesture() {
    if ((activeStroke != null ||
            pendingStampPos != null ||
            pendingPickPos != null ||
            shapeCenter != null) &&
        !_activeIsStylus) {
      _cancelActiveStroke();
    }
    _viewGestureActive = true;
  }

  void endViewGesture() {
    _viewGestureActive = false;
  }

  ui.Rect get _bounds =>
      ui.Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble());

  void setLineArt(RasterizedLineArt art) {
    lineArt?.dispose();
    lineArtPicture?.dispose();
    _lineArtSource?.dispose();
    lineArt = art.image;
    barrierAlpha = art.barrierAlpha;
    lineArtPicture = art.picture;
    _lineArtSource = art.sourcePicture;
    _tick();
  }

  void setPaintLayer(ui.Image? image) {
    paintLayer?.dispose();
    paintLayer = image;
    _tick();
  }

  void setBackground(ui.Image? image) {
    backgroundImage?.dispose();
    backgroundImage = image;
    _tick();
  }

  void setTraceGuide(ui.Picture? picture) {
    traceGuide?.dispose();
    traceGuide = picture;
    _tick();
  }

  void selectTool(ToolKind t) {
    if (t == ToolKind.eyedropper && tool != ToolKind.eyedropper) {
      _toolBeforePick = tool;
    }
    tool = t;
    Sfx.instance.tick();
    notifyListeners();
  }

  void selectSize(double size, {bool silent = false}) {
    brushSize = size.clamp(kMinBrushSize, kMaxBrushSize);
    if (!silent) Sfx.instance.tick();
    notifyListeners();
  }

  void selectColor(Color c) {
    color = c;
    if (tool == ToolKind.eraser) tool = ToolKind.brush;
    if (tool == ToolKind.eyedropper) tool = _toolBeforePick;
    Sfx.instance.tick();
    notifyListeners();
  }

  void selectStamp(String emoji) {
    stampEmoji = emoji;
    stampImage?.dispose();
    stampImage = null;
    stampImagePath = null;
    tool = ToolKind.stamp;
    Sfx.instance.tick();
    notifyListeners();
  }

  /// Ownership of [image] passes to the controller.
  void selectImageStamp(String path, ui.Image image) {
    stampImage?.dispose();
    stampImage = image;
    stampImagePath = path;
    tool = ToolKind.stamp;
    Sfx.instance.tick();
    notifyListeners();
  }

  void selectFillPattern(FillPattern p) {
    fillPattern = p;
    tool = ToolKind.fill;
    Sfx.instance.tick();
    notifyListeners();
  }

  void selectShape(ShapeKind kind) {
    shapeKind = kind;
    tool = ToolKind.shape;
    Sfx.instance.tick();
    notifyListeners();
  }

  void selectSymmetry(int folds) {
    symmetryFolds = kSymmetryFolds.contains(folds) ? folds : 1;
    Sfx.instance.tick();
    _tick(); // guide lines live in the painter
    notifyListeners();
  }

  Offset get canvasCenter =>
      Offset(canvasWidth / 2, canvasHeight / 2);

  double get _baseWidth => brushSize;

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
    // mode) and during pinch gestures, finger touches never draw.
    if (isTouch &&
        (_stylusDown || _viewGestureActive || Settings.instance.stylusOnly)) {
      return;
    }
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
    if (tool == ToolKind.stamp) {
      _activePointer = e.pointer;
      _activeIsStylus = isStylus;
      pendingStampPos = pos;
      _tick();
      return;
    }
    if (tool == ToolKind.eyedropper) {
      _activePointer = e.pointer;
      _activeIsStylus = isStylus;
      pendingPickPos = pos;
      _tick();
      _preparePickBuffer();
      return;
    }
    if (tool == ToolKind.shape) {
      _activePointer = e.pointer;
      _activeIsStylus = isStylus;
      shapeCenter = pos;
      shapeCurrent = pos;
      _tick();
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
    if (pendingStampPos != null && e.pointer == _activePointer) {
      pendingStampPos = _clamp(e.localPosition);
      _tick();
      return;
    }
    if (pendingPickPos != null && e.pointer == _activePointer) {
      pendingPickPos = _clamp(e.localPosition);
      _samplePick();
      _tick();
      return;
    }
    if (shapeCenter != null && e.pointer == _activePointer) {
      shapeCurrent = _clamp(e.localPosition);
      _tick();
      return;
    }
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
    if (pendingStampPos != null) {
      _commitStamp();
      return;
    }
    if (pendingPickPos != null) {
      _commitPick();
      return;
    }
    if (shapeCenter != null) {
      _commitShape();
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
    pendingStampPos = null;
    pendingPickPos = null;
    pickedPreview = null;
    _pickBuffer = null;
    shapeCenter = null;
    shapeCurrent = null;
    _activePointer = null;
    _activeIsStylus = false;
    _tick();
  }

  // ------------------------------------------------------------- eyedropper

  /// Composites all visible layers once per pick gesture into an RGBA
  /// buffer, so every finger move afterwards is a plain array lookup. The
  /// buffer is released when the finger lifts.
  Future<void> _preparePickBuffer() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, _bounds);
    canvas.drawRect(_bounds, Paint()..color = const Color(0xFFFFFFFF));
    if (backgroundImage != null) {
      canvas.drawImage(backgroundImage!, Offset.zero, Paint());
    }
    if (paintLayer != null) {
      canvas.drawImage(paintLayer!, Offset.zero, Paint());
    }
    if (lineArtPicture != null) {
      canvas.drawPicture(lineArtPicture!);
    } else if (lineArt != null) {
      canvas.drawImage(lineArt!, Offset.zero, Paint());
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(canvasWidth, canvasHeight);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (pendingPickPos == null) return; // gesture ended while compositing
    _pickBuffer = data?.buffer.asUint8List();
    _samplePick();
    _tick();
  }

  void _samplePick() {
    final buf = _pickBuffer;
    final pos = pendingPickPos;
    if (buf == null || pos == null) return;
    pickedPreview = colorAtRgba(
        buf, canvasWidth, canvasHeight, pos.dx.floor(), pos.dy.floor());
  }

  void _commitPick() {
    final picked = pickedPreview;
    pendingPickPos = null;
    pickedPreview = null;
    _pickBuffer = null;
    _activePointer = null;
    _activeIsStylus = false;
    if (picked != null) {
      color = picked;
      Settings.instance.registerRecentColor(picked);
      tool = _toolBeforePick;
      Sfx.instance.pop();
      notifyListeners();
    }
    _tick();
  }

  void _commitStamp() {
    final pos = pendingStampPos;
    if (pos == null) return;
    pendingStampPos = null;
    _activePointer = null;
    _activeIsStylus = false;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, _bounds);
    if (paintLayer != null) {
      canvas.drawImage(paintLayer!, Offset.zero, Paint());
    }
    for (final copy in symmetryCopies(symmetryFolds)) {
      // Transform the position, not the canvas — motifs stay upright.
      final p = symmetryPoint(pos, canvasCenter, copy);
      if (stampImage != null) {
        StrokeRenderer.drawImageStamp(
            canvas, stampImage!, p, stampSizeFor(brushSize));
      } else {
        StrokeRenderer.drawStamp(canvas, stampEmoji, p,
            stampSizeFor(brushSize));
      }
    }
    final picture = recorder.endRecording();
    final newLayer = picture.toImageSync(canvasWidth, canvasHeight);
    picture.dispose();
    Sfx.instance.pop();
    Progress.instance.registerToolUsed(ToolKind.stamp);
    _pushUndoAndReplace(newLayer);
    // Reset first so re-stamping the same spot still notifies.
    lastStamp.value = null;
    lastStamp.value = pos;
  }

  /// Radius of the shape currently being dragged. A bare tap still yields
  /// a visible shape (min 20 canvas px).
  double get shapeRadius {
    final c = shapeCenter, p = shapeCurrent;
    if (c == null || p == null) return 0;
    return max(20.0, (p - c).distance);
  }

  void _commitShape() {
    final center = shapeCenter;
    if (center == null) return;
    final radius = shapeRadius;
    shapeCenter = null;
    shapeCurrent = null;
    _activePointer = null;
    _activeIsStylus = false;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, _bounds);
    if (paintLayer != null) {
      canvas.drawImage(paintLayer!, Offset.zero, Paint());
    }
    ShapeRenderer.drawShape(canvas, shapeKind, center, radius, color, brushSize * 0.4);
    final picture = recorder.endRecording();
    final newLayer = picture.toImageSync(canvasWidth, canvasHeight);
    picture.dispose();
    Sfx.instance.pop();
    Progress.instance.registerToolUsed(ToolKind.shape);
    _pushUndoAndReplace(newLayer);
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
    for (final copy in symmetryCopies(symmetryFolds)) {
      canvas.save();
      applySymmetryTransform(canvas, canvasCenter, copy);
      StrokeRenderer.draw(canvas, stroke);
      canvas.restore();
    }
    if (erasing) canvas.restore();
    final picture = recorder.endRecording();
    final newLayer = picture.toImageSync(canvasWidth, canvasHeight);
    picture.dispose();

    Progress.instance.registerToolUsed(stroke.kind);
    _pushUndoAndReplace(newLayer);
    onStrokeCommitted?.call(stroke);
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
      final pattern = fillPattern;
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
            pattern: pattern,
          ));
      if (result != null) {
        final newLayer = await rgbaToImage(result, w, h);
        Sfx.instance.pop();
        Progress.instance.registerToolUsed(ToolKind.fill);
        _pushUndoAndReplace(newLayer);
        // Reset first so refilling the same spot still notifies.
        lastFill.value = null;
        lastFill.value = pos;
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
    lineArtPicture?.dispose();
    _lineArtSource?.dispose();
    backgroundImage?.dispose();
    traceGuide?.dispose();
    stampImage?.dispose();
    lastFill.dispose();
    lastStamp.dispose();
    repaint.dispose();
    super.dispose();
  }
}
