import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/draw_op.dart';
import '../models/tool.dart';
import '../util/color_utils.dart';
import '../util/progress.dart';
import '../util/settings.dart';
import '../util/sfx.dart';
import '../util/svg_raster.dart';
import 'fill_pattern.dart';
import 'op_apply.dart';
import 'stroke.dart';
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

  /// Where a fill tap landed without filling anything — on a line, or in an
  /// area that already had this colour. Drives a small "nothing here" ring,
  /// because the answer to a tap must never be nothing at all.
  final ValueNotifier<Offset?> missedFill = ValueNotifier<Offset?>(null);

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

  /// Color-by-number veto: called before a fill tap; returning false skips
  /// the fill (the screen owns region/number matching and feedback).
  bool Function(Offset pos)? fillGuard;

  /// Number chips the painter draws over the line art in CbN mode.
  List<({Offset pos, int number, bool filled})>? cbnLabels;

  void setCbnLabels(List<({Offset pos, int number, bool filled})>? labels) {
    cbnLabels = labels;
    _tick();
  }

  Uint8List? barrierAlpha;
  Stroke? activeStroke;

  ToolKind tool = ToolKind.brush;
  double brushSize = 28;
  Color color = kPaletteColors.first;
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

  /// The word the letters tool will write, chosen in its sheet. Null until
  /// a child has typed something — the tool then behaves like the sticker
  /// tool with a word instead of an emoji.
  String? stampText;

  /// Center and current drag position of a shape being placed.
  Offset? shapeCenter;
  Offset? shapeCurrent;

  /// Whether shapes are drawn as an edge instead of a filled area. Chosen in
  /// the shape sheet, not the toolbar: it belongs to the motif, and the rail
  /// is already the longest strip on the screen.
  bool shapeOutline = false;

  /// [shapeAngle] frozen at the moment the drag ended — the drag state is
  /// cleared before the shape is painted.
  double shapeAngleAtCommit = 0;

  /// Live position of an eyedropper pick (finger still down) and the color
  /// currently under it — drives the loupe overlay.
  Offset? pendingPickPos;
  Color? pickedPreview;
  Uint8List? _pickBuffer;

  /// Where the finger was when it lifted before the pick buffer had landed.
  /// Compositing 12 MB takes a moment, and a quick tap is the ordinary way
  /// to use an eyedropper — it used to fall into that gap and do nothing.
  Offset? _pickAwaitingBuffer;
  ToolKind _toolBeforePick = ToolKind.brush;

  late final UndoStack _undoStack =
      UndoStack(width: canvasWidth, height: canvasHeight);
  bool get canUndo => _undoStack.canUndo;
  bool get canRedo => _undoStack.canRedo;

  /// How many steps back are actually available. The screen does not need
  /// it; the tests that guard the patch stack do.
  @visibleForTesting
  int get undoDepth => _undoStack.depth;

  ui.Rect get _wholeCanvas => _bounds;

  /// Area a stroke can reach.
  ///
  /// Generous on purpose: neon glows and glitter scatter well past the
  /// nominal width, and a rect one pixel too small leaves stale pixels
  /// behind on undo. Over-reporting only costs a few kilobytes of history —
  /// `test/undo_patch_test.dart` is what says whether it is enough.
  ui.Rect _strokeDirtyRect(Stroke stroke) {
    if (symmetryFolds > 1 || stroke.points.isEmpty) return _wholeCanvas;
    var box = ui.Rect.fromCircle(center: stroke.points.first.pos, radius: 0);
    for (final p in stroke.points) {
      box = box.expandToInclude(ui.Rect.fromCircle(center: p.pos, radius: 0));
    }
    return box.inflate(stroke.baseWidth * 2 + 48);
  }

  // ----------------------------------------------------------------- op log

  /// Whether committed operations are recorded for the time-lapse replay.
  /// Off for legacy artworks resumed without an op log (their existing
  /// paint would be missing from the story) and for future multi-controller
  /// modes.
  bool recordOps = true;

  static const int kMaxOps = 4000;
  final List<DrawOp> _ops = [];
  int _opCursor = 0;
  bool _opsFrozen = false;

  /// The committed story so far (undo-aware).
  List<DrawOp> get opsSnapshot =>
      List.unmodifiable(_ops.sublist(0, _opCursor));

  bool get hasOps => _opCursor > 0;

  void loadOps(List<DrawOp> ops) {
    _ops
      ..clear()
      ..addAll(ops.take(kMaxOps));
    _opCursor = _ops.length;
    _opsFrozen = ops.length >= kMaxOps;
  }

  /// Once the cap is hit the log freezes entirely (no appends, no cursor
  /// moves) — the replay then tells "the story so far" and can never
  /// desync from partial recording.
  void _recordOp(DrawOp op) {
    if (!recordOps || _opsFrozen) return;
    if (_ops.length > _opCursor) {
      _ops.removeRange(_opCursor, _ops.length);
    }
    if (_ops.length >= kMaxOps) {
      _opsFrozen = true;
      return;
    }
    _ops.add(op);
    _opCursor = _ops.length;
  }

  bool isFilling = false;
  bool dirty = false;

  /// Bumped on every change to the paint layer. The save path snapshots it
  /// before encoding and only clears [dirty] if it is still unchanged —
  /// otherwise strokes drawn during the (async) encode would be marked
  /// saved without ever having been written.
  int revision = 0;

  bool get isEmpty => paintLayer == null;

  /// Set in [dispose]. The fill and eyedropper paths await work that can
  /// outlive the screen (isolate round-trips, image decoding); touching the
  /// layers or notifiers afterwards would double-dispose an image and fire
  /// a disposed ValueNotifier.
  bool _disposed = false;

  int? _activePointer;
  bool _activeIsStylus = false;
  bool _stylusDown = false;
  bool _viewGestureActive = false;
  final Random _rng = Random();

  /// True while a stylus is touching the screen (viewport uses this to
  /// ignore pinches from a resting hand).
  bool get stylusDown => _stylusDown;

  /// Called by the viewport when a two-finger pinch starts.
  ///
  /// What is already **visible** gets committed; what is only *pending*
  /// falls away. A half-drawn stroke used to be discarded here, which meant
  /// a second finger — a resting thumb, a sibling's hand — erased the line
  /// a child was drawing with no sound, no message and nothing to undo,
  /// because nothing was ever written. Committing is recoverable in one
  /// tap; discarding is not recoverable at all.
  ///
  /// A pending stamp or eyedropper tap has drawn nothing yet, so there is
  /// nothing to lose and it still falls away.
  void beginViewGesture() {
    if (!_activeIsStylus) {
      if (activeStroke != null) {
        _commitActiveStroke();
      } else if (shapeCenter != null) {
        _commitShape();
      } else if (pendingStampPos != null || pendingPickPos != null) {
        _cancelActiveStroke();
      }
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

  /// Color-by-number: sets the palette color and the fill tool without the
  /// selection tick (the CbN palette drives its own feedback).
  void selectCbnColor(Color c) {
    color = c;
    tool = ToolKind.fill;
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

  /// Contact radius (device px) above which a touch is a hand, not a finger.
  ///
  /// A child's fingertip reports roughly 5–15; a palm or a forearm laid
  /// across a tablet reports far more. The number is deliberately high: the
  /// cost of rejecting a real finger is a line that never appears, which is
  /// far worse than the occasional palm mark a child can undo.
  ///
  /// Only meaningful where the platform measures contacts at all. Plenty of
  /// Android devices report 0 for every pointer, and there the two rules
  /// below simply never fire — the behaviour stays exactly as it was.
  static const double _palmRadius = 42;

  static bool _looksLikePalm(PointerEvent e) =>
      e.kind == PointerDeviceKind.touch && e.radiusMajor > _palmRadius;

  /// Contact radius of the touch currently drawing, or 0 when unknown.
  double _activeRadius = 0;

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
    // A hand laid flat on the paper is not a request to draw. Only ever the
    // *start* of a stroke is judged this way — a contact that spreads while
    // it draws is a child pressing harder, not a palm arriving.
    if (_looksLikePalm(e) && activeStroke == null) return;
    if (isStylus) _stylusDown = true;

    if (activeStroke != null) {
      // The pen wins over the hand that was resting before it landed, and
      // for the same reason a fingertip wins over a palm: whichever contact
      // is smaller is the one the child is pointing with.
      final fingerBeatsPalm = isTouch &&
          _activeRadius > _palmRadius &&
          e.radiusMajor > 0 &&
          e.radiusMajor < _activeRadius / 2;
      if ((isStylus && !_activeIsStylus) || fingerBeatsPalm) {
        _cancelActiveStroke();
      } else {
        return; // ignore extra fingers while drawing
      }
    }
    _activeRadius = e.radiusMajor;

    final pos = _clamp(e.localPosition);
    if (tool == ToolKind.fill) {
      if (fillGuard?.call(pos) == false) return;
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
    if (tool == ToolKind.text) {
      // Nothing typed yet, so there is nothing to place. Silently doing
      // nothing is the one answer this app does not give — the sheet is
      // opened from the toolbar, and a stray tap here should not paint.
      if ((stampText ?? '').isEmpty) return;
      _activePointer = e.pointer;
      _activeIsStylus = isStylus;
      pendingTextPos = pos;
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
    // A palm often lands on a small edge and only then settles into its full
    // area, so the widest it has ever been is the honest measure — otherwise
    // a hand that spreads after touchdown would never be recognised as one.
    if (e.pointer == _activePointer && e.radiusMajor > _activeRadius) {
      _activeRadius = e.radiusMajor;
    }
    if (pendingTextPos != null && e.pointer == _activePointer) {
      pendingTextPos = _clamp(e.localPosition);
      _tick();
      return;
    }
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
    if (pendingTextPos != null) {
      _commitText();
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
    pendingTextPos = null;
    pendingPickPos = null;
    pickedPreview = null;
    _pickBuffer = null;
    _pickAwaitingBuffer = null;
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
    if (_disposed) return;
    // The gesture may already be over. A quick tap is the normal way to use
    // an eyedropper, so "the finger lifted" is not the same as "never mind".
    final waiting = pendingPickPos ?? _pickAwaitingBuffer;
    if (waiting == null) return;
    _pickBuffer = data?.buffer.asUint8List();
    if (pendingPickPos == null) {
      pendingPickPos = waiting;
      _pickAwaitingBuffer = null;
      _samplePick();
      _commitPick();
      return;
    }
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
    final pos = pendingPickPos;
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
    } else if (pos != null) {
      // Lifted before the composite landed. Hold on to the spot so the pick
      // completes when it does, instead of the tap doing nothing at all.
      _pickAwaitingBuffer = pos;
    }
    _tick();
  }

  void _commitStamp() {
    final pos = pendingStampPos;
    if (pos == null) return;
    pendingStampPos = null;
    _activePointer = null;
    _activeIsStylus = false;

    final newLayer = applyStamp(
      layer: paintLayer,
      emoji: stampImage == null ? stampEmoji : null,
      image: stampImage,
      pos: pos,
      size: stampSizeFor(brushSize),
      symmetryFolds: symmetryFolds,
      width: canvasWidth,
      height: canvasHeight,
    );
    Sfx.instance.pop();
    Progress.instance.registerToolUsed(ToolKind.stamp);
    _pushUndoAndReplace(
      newLayer,
      symmetryFolds > 1
          ? _wholeCanvas
          : ui.Rect.fromCircle(center: pos, radius: stampSizeFor(brushSize)),
    );
    _recordOp(StampOp(
      emoji: stampImage == null ? stampEmoji : null,
      imagePath: stampImagePath,
      x: pos.dx,
      y: pos.dy,
      size: stampSizeFor(brushSize),
      symmetryFolds: symmetryFolds,
    ));
    // Reset first so re-stamping the same spot still notifies.
    lastStamp.value = null;
    lastStamp.value = pos;
  }

  /// Where the word will land while the finger is still down.
  Offset? pendingTextPos;

  /// Cap height of the word, tied to the brush size the way a sticker is.
  double textSizeFor(double brush) => brush * 2.4;

  void _commitText() {
    final pos = pendingTextPos;
    final text = stampText;
    pendingTextPos = null;
    _activePointer = null;
    _activeIsStylus = false;
    if (pos == null || text == null || text.isEmpty) return;

    final size = textSizeFor(brushSize);
    final newLayer = applyText(
      layer: paintLayer,
      text: text,
      pos: pos,
      size: size,
      color: color,
      symmetryFolds: symmetryFolds,
      width: canvasWidth,
      height: canvasHeight,
    );
    Sfx.instance.pop();
    Progress.instance.registerToolUsed(ToolKind.text);
    _pushUndoAndReplace(
      newLayer,
      symmetryFolds > 1
          ? _wholeCanvas
          // A word is wide, not square: the dirty box has to cover the whole
          // line or the last letters are left behind on an undo.
          : ui.Rect.fromCenter(
              center: pos,
              width: size * text.length + size,
              height: size * 2,
            ),
    );
    _recordOp(TextOp(
      text: text,
      x: pos.dx,
      y: pos.dy,
      size: size,
      color: color.toARGB32(),
      symmetryFolds: symmetryFolds,
    ));
  }

  /// Radius of the shape currently being dragged. A bare tap still yields
  /// a visible shape (min 20 canvas px).
  double get shapeRadius {
    final c = shapeCenter, p = shapeCurrent;
    if (c == null || p == null) return 0;
    return max(20.0, (p - c).distance);
  }

  /// Direction of the drag. Only the line uses it; a bare tap has no
  /// direction and lies flat.
  double get shapeAngle {
    final c = shapeCenter, p = shapeCurrent;
    if (c == null || p == null || (p - c).distance < 1) return 0;
    return (p - c).direction;
  }

  void _commitShape() {
    final center = shapeCenter;
    if (center == null) return;
    final radius = shapeRadius;
    // Read before the drag state is cleared below.
    shapeAngleAtCommit = shapeAngle;
    shapeCenter = null;
    shapeCurrent = null;
    _activePointer = null;
    _activeIsStylus = false;

    final newLayer = applyShape(
      layer: paintLayer,
      kind: shapeKind,
      center: center,
      radius: radius,
      color: color,
      strokeWidth: brushSize * 0.4,
      angle: shapeAngleAtCommit,
      outline: shapeOutline,
      width: canvasWidth,
      height: canvasHeight,
    );
    Sfx.instance.pop();
    Progress.instance.registerToolUsed(ToolKind.shape);
    _pushUndoAndReplace(
      newLayer,
      symmetryFolds > 1
          ? _wholeCanvas
          : ui.Rect.fromCircle(
              center: center,
              radius: radius + brushSize * 0.4,
            ).inflate(48),
    );
    _recordOp(ShapeOp(
      kind: shapeKind,
      x: center.dx,
      y: center.dy,
      radius: radius,
      color: color.toARGB32(),
      strokeWidth: brushSize * 0.4,
      angle: shapeAngleAtCommit,
      outline: shapeOutline,
    ));
  }

  void _commitActiveStroke() {
    final stroke = activeStroke;
    if (stroke == null) return;
    activeStroke = null;
    _activePointer = null;
    _activeIsStylus = false;

    final newLayer = applyStroke(
      layer: paintLayer,
      stroke: stroke,
      symmetryFolds: symmetryFolds,
      width: canvasWidth,
      height: canvasHeight,
    );
    // Drawing answers for itself — the line appears under the finger. The
    // eraser is the exception: what it does is make something *stop* being
    // there, and "did that work?" is hardest to answer where the answer is
    // an absence.
    if (stroke.kind == ToolKind.eraser) Sfx.instance.tick();
    Progress.instance.registerToolUsed(stroke.kind);
    _pushUndoAndReplace(newLayer, _strokeDirtyRect(stroke));
    _recordOp(StrokeOp(
      toolKind: stroke.kind,
      color: stroke.color.toARGB32(),
      baseWidth: stroke.baseWidth,
      seed: stroke.seed,
      symmetryFolds: symmetryFolds,
      points: [
        for (final p in stroke.points) ...[p.pos.dx, p.pos.dy, p.pressure],
      ],
    ));
    onStrokeCommitted?.call(stroke);
  }

  /// [dirtyRect] is the area the new layer differs from the old one in — the
  /// only part the history has to remember. Pass [_wholeCanvas] where that
  /// cannot be bounded honestly.
  void _pushUndoAndReplace(ui.Image? newLayer, ui.Rect dirtyRect) {
    _undoStack.push(paintLayer, dirtyRect);
    paintLayer?.dispose();
    paintLayer = newLayer;
    dirty = true;
    revision++;
    _tick();
    notifyListeners();
  }

  // ------------------------------------------------------------------- fill

  Future<void> tapFill(Offset pos) async {
    if (isFilling || activeStroke != null) return;
    isFilling = true;
    notifyListeners();
    try {
      final c = color;
      final pattern = fillPattern;
      final newLayer = await applyFill(
        layer: paintLayer,
        barrierAlpha: barrierAlpha,
        pos: pos,
        color: c,
        pattern: pattern,
        width: canvasWidth,
        height: canvasHeight,
      );
      // The screen can be gone by now — the isolate round-trip is slow.
      if (_disposed) {
        newLayer?.dispose();
        return;
      }
      if (newLayer != null) {
        Sfx.instance.pop();
        Progress.instance.registerToolUsed(ToolKind.fill);
        // A flood fill runs until it hits a barrier: it can reach anywhere,
        // and saying so costs less than guessing wrong.
        _pushUndoAndReplace(newLayer, _wholeCanvas);
        _recordOp(FillOp(
          x: pos.dx,
          y: pos.dy,
          color: c.toARGB32(),
          pattern: pattern,
        ));
        // Reset first so refilling the same spot still notifies.
        lastFill.value = null;
        lastFill.value = pos;
      } else {
        // The fill found nothing to do — the tap landed on a line, or the
        // area already had this colour. Every other outcome in the app
        // answers; this one used to be silence, which reads as "the app is
        // broken" and invites tapping harder.
        Sfx.instance.tick();
        missedFill.value = null;
        missedFill.value = pos;
      }
    } finally {
      if (!_disposed) {
        isFilling = false;
        notifyListeners();
      }
    }
  }

  // -------------------------------------------------------------- undo/clear

  void undo() {
    if (!canUndo) return;
    paintLayer = _undoStack.undo(paintLayer);
    if (!_opsFrozen && _opCursor > 0) _opCursor--;
    dirty = true;
    revision++;
    _tick();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    paintLayer = _undoStack.redo(paintLayer);
    if (!_opsFrozen && _opCursor < _ops.length) _opCursor++;
    dirty = true;
    revision++;
    _tick();
    notifyListeners();
  }

  void clearAll() {
    if (paintLayer == null) return;
    // The picture used to simply vanish: no sound, no movement, nothing to
    // tell a child their tap was what did it. The biggest change on the
    // screen was the one with the least to say about itself.
    Sfx.instance.pop();
    _pushUndoAndReplace(null, _wholeCanvas);
    _recordOp(const ClearOp());
  }

  /// Hands the undo history's spare memory back. Called when the app goes to
  /// the background: that is when Android decides which process to reclaim,
  /// and tens of megabytes of history is exactly the kind of thing that
  /// decides it. The picture is saved by then.
  ///
  /// Since v8.7 this trims to a budget instead of down to one step — a step
  /// is a patch now, so an ordinary afternoon of drawing survives being
  /// interrupted.
  void releaseMemory() {
    _undoStack.trimToBackgroundBudget();
    notifyListeners();
  }

  void _tick() => repaint.value++;

  @override
  void dispose() {
    _disposed = true;
    _undoStack.dispose();
    paintLayer?.dispose();
    lineArt?.dispose();
    lineArtPicture?.dispose();
    _lineArtSource?.dispose();
    backgroundImage?.dispose();
    traceGuide?.dispose();
    stampImage?.dispose();
    lastFill.dispose();
    missedFill.dispose();
    lastStamp.dispose();
    repaint.dispose();
    super.dispose();
  }
}
