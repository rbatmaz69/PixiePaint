import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data' show Uint16List;
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../gallery/artwork_store.dart';
import '../l10n/l10n.dart';
import '../models/artwork.dart';
import '../models/cbn_spec.dart';
import '../models/coloring_page.dart';
import '../models/draw_op.dart';
import '../models/scene.dart';
import '../models/tool.dart';
import '../photo/photo_lineart.dart';
import '../ui/app_theme.dart';
import '../ui/bouncy.dart';
import '../ui/loading_pixie.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../models/reward.dart';
import '../trace/trace_coverage.dart';
import '../trace/trace_template.dart';
import '../ui/reward_reveal.dart';
import '../util/image_io.dart';
import '../util/progress.dart';
import '../util/review.dart';
import '../util/settings.dart';
import '../util/sfx.dart';
import '../util/share.dart' as share_util;
import '../util/svg_raster.dart';
import '../widgets/cbn_palette.dart';
import '../widgets/color_palette.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/parental_gate.dart';
import '../widgets/shape_picker.dart' as shapes;
import '../widgets/tool_bar.dart';
import 'canvas_controller.dart';
import 'canvas_viewport.dart';
import 'fill_pattern.dart';
import 'painting_canvas.dart';
import 'region_label.dart';
import 'stroke.dart';

const int kCanvasWidth = 2048;
const int kCanvasHeight = 1536;

/// The drawing screen: pass [page] to color a bundled picture, [resume] to
/// continue a saved artwork, [photoPath] to paint over a picked photo,
/// [photoLineArt] to color line art detected from a photo, nothing for free
/// drawing.
class CanvasScreen extends StatefulWidget {
  const CanvasScreen({
    super.key,
    this.page,
    this.resume,
    this.photoPath,
    this.photoLineArt,
    this.traceTemplate,
    this.scene,
  });

  final ColoringPage? page;
  final Artwork? resume;
  final String? photoPath;
  final TraceTemplate? traceTemplate;

  /// A ready-made stage rendered into the (eraser-proof) photo background.
  final Scene? scene;

  /// Ownership passes to the canvas controller, which disposes it.
  final RasterizedLineArt? photoLineArt;

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with WidgetsBindingObserver {
  late final CanvasController controller;
  final CanvasViewportController viewport = CanvasViewportController();
  late final String artworkId;
  String? pageId;
  String? traceId;
  String? sceneId;
  TraceCoverage? _traceCoverage;
  bool _traceCelebrated = false;

  // Color-by-number state (null/empty outside CbN mode).
  CbnSpec? _cbnSpec;
  Uint16List? _regionOf;
  final Map<int, int> _regionNumber = {};
  final Set<int> _cbnFilledRegions = {};
  int? _cbnSelected;
  int? _cbnHint;
  int _cbnWrongTries = 0;
  Timer? _cbnHintTimer;
  bool _cbnCelebrated = false;
  bool get _isCbn => _cbnSpec != null;
  late bool hasPhoto;
  late bool hasPhotoLineArt;
  late bool _backgroundSaved;
  late bool _lineArtSaved;
  bool loading = true;
  bool everSaved = false;
  Timer? _autoSave;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = CanvasController(
      canvasWidth: kCanvasWidth,
      canvasHeight: kCanvasHeight,
    );
    artworkId = widget.resume?.id ?? ArtworkStore.newId();
    pageId = widget.resume?.pageId ?? widget.page?.id;
    traceId = widget.traceTemplate?.id ?? widget.resume?.traceId;
    sceneId = widget.scene?.id ?? widget.resume?.sceneId;
    // A scene is persisted exactly like a photo background: rendered once,
    // saved as background.png, protected from the eraser.
    hasPhoto = widget.photoPath != null ||
        widget.scene != null ||
        (widget.resume?.hasPhoto ?? false);
    hasPhotoLineArt =
        widget.photoLineArt != null ||
        (widget.resume?.hasPhotoLineArt ?? false);
    _backgroundSaved = widget.resume?.hasPhoto ?? false;
    _lineArtSaved = widget.resume?.hasPhotoLineArt ?? false;
    everSaved = widget.resume != null;
    _load();
    _autoSave = Timer.periodic(const Duration(seconds: 30), (_) {
      if (controller.dirty) _save();
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _load() async {
    if (traceId != null) {
      await _loadTrace(traceId!);
    }
    if (pageId != null) {
      final page = await ColoringPage.byId(pageId!);
      if (page != null) {
        final art = await rasterizeSvgAsset(
          page.assetPath,
          kCanvasWidth,
          kCanvasHeight,
        );
        controller.setLineArt(art);
        if (page.isColorByNumber) await _loadCbn(page);
      }
    }
    if (widget.photoLineArt != null) {
      controller.setLineArt(widget.photoLineArt!);
    } else if ((widget.resume?.hasPhotoLineArt ?? false) &&
        await widget.resume!.lineArtFile.exists()) {
      controller.setLineArt(
        await lineArtFromPng(await widget.resume!.lineArtFile.readAsBytes()),
      );
    }
    final photoPath = widget.photoPath;
    if (widget.scene != null) {
      controller.setBackground(await rasterizeSvgToImage(
          widget.scene!.assetPath, kCanvasWidth, kCanvasHeight));
    } else if (photoPath != null) {
      final bytes = await File(photoPath).readAsBytes();
      controller.setBackground(
        await normalizePhoto(bytes, kCanvasWidth, kCanvasHeight),
      );
    } else if ((widget.resume?.hasPhoto ?? false) &&
        await widget.resume!.backgroundFile.exists()) {
      final bytes = await widget.resume!.backgroundFile.readAsBytes();
      controller.setBackground(await pngBytesToImage(bytes));
    }
    final resume = widget.resume;
    if (resume != null && await resume.paintFile.exists()) {
      final bytes = await resume.paintFile.readAsBytes();
      controller.setPaintLayer(await pngBytesToImage(bytes));
    }
    if (resume != null) {
      if (await resume.opsFile.exists()) {
        controller.loadOps(decodeOps(await resume.opsFile.readAsString()));
      } else if (controller.paintLayer != null) {
        // Legacy artwork painted before the op log existed — recording now
        // would tell a story that misses everything already on the canvas.
        controller.recordOps = false;
      }
    }
    if (mounted) setState(() => loading = false);
  }

  /// Builds the trace guide + coverage grid and wires the commit hook. The
  /// guide is regenerated from the template id — nothing rasterized is
  /// persisted. On resume the coverage restarts, but an already-earned
  /// completion never fires twice.
  Future<void> _loadTrace(String id) async {
    final template = traceTemplateById(id);
    if (template == null) return;
    final guide = buildTraceGuide(template, kCanvasWidth, kCanvasHeight);
    controller.setTraceGuide(guide);
    final image = await guide.toImage(kCanvasWidth, kCanvasHeight);
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    image.dispose();
    final rgba = data!.buffer.asUint8List();
    final alpha = Uint8List(kCanvasWidth * kCanvasHeight);
    for (var i = 0; i < alpha.length; i++) {
      alpha[i] = rgba[i * 4 + 3];
    }
    _traceCoverage =
        TraceCoverage.fromAlpha(alpha, kCanvasWidth, kCanvasHeight);
    _traceCelebrated = Progress.instance.completedTraceIds.contains(id);
    controller.onStrokeCommitted = _onTraceStroke;
  }

  /// Color-by-number setup: labels the enclosed regions of the rasterized
  /// line art (isolate), maps each sidecar label to its region id, restores
  /// already-solved regions and wires the fill guard.
  Future<void> _loadCbn(ColoringPage page) async {
    final spec = await CbnSpec.load(page.id);
    final alpha = controller.barrierAlpha;
    if (spec == null || alpha == null) return;
    const w = kCanvasWidth, h = kCanvasHeight;
    final regionOf = await Isolate.run(() => labelRegions(alpha, w, h));
    _regionNumber.clear();
    for (final label in spec.labels) {
      final x = label.pos.dx.floor().clamp(0, w - 1);
      final y = label.pos.dy.floor().clamp(0, h - 1);
      final id = regionOf[y * w + x];
      // id 0 would mean the label sits on an outline — authoring bug,
      // tolerated by simply skipping that label.
      if (id != 0) _regionNumber[id] = label.number;
    }
    _cbnSpec = spec;
    _regionOf = regionOf;
    _cbnFilledRegions.addAll(widget.resume?.cbnFilled ?? const []);
    _cbnCelebrated = _cbnComplete ||
        Progress.instance.completedCbnIds.contains(page.id);
    controller
      ..tool = ToolKind.fill
      ..fillPattern = FillPattern.solid
      ..fillGuard = _cbnFillGuard
      ..lastFill.addListener(_onCbnFill);
    _selectCbnNumber(_firstOpenNumber ?? spec.numbers.first, silent: true);
    _pushCbnLabels();
  }

  bool get _cbnComplete =>
      _regionNumber.isNotEmpty &&
      _regionNumber.keys.every(_cbnFilledRegions.contains);

  Set<int> get _cbnDoneNumbers {
    final spec = _cbnSpec;
    if (spec == null) return const {};
    final done = <int>{};
    for (final n in spec.numbers) {
      final regions = [
        for (final e in _regionNumber.entries)
          if (e.value == n) e.key
      ];
      if (regions.isNotEmpty && regions.every(_cbnFilledRegions.contains)) {
        done.add(n);
      }
    }
    return done;
  }

  int? get _firstOpenNumber {
    final spec = _cbnSpec;
    if (spec == null) return null;
    final done = _cbnDoneNumbers;
    for (final n in spec.numbers) {
      if (!done.contains(n)) return n;
    }
    return null;
  }

  void _selectCbnNumber(int n, {bool silent = false}) {
    final color = _cbnSpec?.colorOf[n];
    if (color == null) return;
    setState(() => _cbnSelected = n);
    controller.selectCbnColor(color);
    if (!silent) Sfx.instance.tick();
  }

  void _pushCbnLabels() {
    final spec = _cbnSpec;
    final regionOf = _regionOf;
    if (spec == null || regionOf == null) return;
    controller.setCbnLabels([
      for (final label in spec.labels)
        (
          pos: label.pos,
          number: label.number,
          filled: _cbnFilledRegions.contains(regionOf[
              label.pos.dy.floor().clamp(0, kCanvasHeight - 1) *
                      kCanvasWidth +
                  label.pos.dx.floor().clamp(0, kCanvasWidth - 1)]),
        ),
    ]);
  }

  bool _cbnFillGuard(Offset pos) {
    final regionOf = _regionOf;
    if (regionOf == null) return true;
    final id = regionOf[pos.dy.floor().clamp(0, kCanvasHeight - 1) *
            kCanvasWidth +
        pos.dx.floor().clamp(0, kCanvasWidth - 1)];
    final number = _regionNumber[id];
    // Unlabeled areas (background etc.) are free to fill — forgiving.
    if (number == null || number == _cbnSelected) return true;
    _onCbnWrong(number);
    return false;
  }

  /// Never punitive: a soft tick, and after two misses the right swatch
  /// pulses to show where to look.
  void _onCbnWrong(int correctNumber) {
    Sfx.instance.tick();
    _cbnWrongTries++;
    if (_cbnWrongTries >= 2) {
      _cbnHintTimer?.cancel();
      setState(() => _cbnHint = correctNumber);
      _cbnHintTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _cbnHint = null);
      });
    }
  }

  void _onCbnFill() {
    final pos = controller.lastFill.value;
    final regionOf = _regionOf;
    if (pos == null || regionOf == null) return;
    final id = regionOf[pos.dy.floor().clamp(0, kCanvasHeight - 1) *
            kCanvasWidth +
        pos.dx.floor().clamp(0, kCanvasWidth - 1)];
    if (_regionNumber[id] == null || !_cbnFilledRegions.add(id)) return;
    _cbnWrongTries = 0;
    _pushCbnLabels();
    // Hop to the next open number so the kid always knows what's next.
    final next = _firstOpenNumber;
    if (next != null && _cbnDoneNumbers.contains(_cbnSelected)) {
      _selectCbnNumber(next, silent: true);
    }
    setState(() {});
    if (_cbnComplete && !_cbnCelebrated) {
      _cbnCelebrated = true;
      Progress.instance.registerCbnCompleted(pageId!);
      Sfx.instance.tada();
      if (mounted) showConfetti(context);
    }
  }

  void _onTraceStroke(Stroke stroke) {
    final coverage = _traceCoverage;
    if (coverage == null || stroke.kind == ToolKind.eraser) return;
    coverage.addPoints(
      stroke.points.map((p) => p.pos),
      // Generous radius for small hands: at least half a fat finger.
      stroke.baseWidth < 30 ? 30 : stroke.baseWidth,
    );
    if (!_traceCelebrated && coverage.fraction >= 0.6) {
      _traceCelebrated = true;
      Progress.instance.registerTraceCompleted(traceId!);
      Sfx.instance.tada();
      if (mounted) showConfetti(context);
    }
  }

  Future<void> _save() async {
    if (!controller.dirty && everSaved) return;
    // Don't create junk artworks for an untouched canvas.
    if (controller.isEmpty && !everSaved) return;
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
      width: kCanvasWidth,
      height: kCanvasHeight,
      background: controller.backgroundImage,
      paintLayer: controller.paintLayer,
      lineArt: controller.lineArt,
      targetWidth: 360,
    );
    final thumbPng = await imageToPngBytes(thumb);
    thumb.dispose();
    await ArtworkStore.save(
      id: artworkId,
      pageId: pageId,
      traceId: traceId,
      sceneId: sceneId,
      cbnFilled: _cbnFilledRegions.toList(),
      hasPhoto: hasPhoto,
      hasPhotoLineArt: hasPhotoLineArt,
      width: kCanvasWidth,
      height: kCanvasHeight,
      paintPng: paintPng,
      backgroundPng: backgroundPng,
      lineArtPng: lineArtPng,
      thumbPng: thumbPng,
      opsJson: controller.recordOps && controller.hasOps
          ? encodeOps(controller.opsSnapshot)
          : null,
    );
    if (backgroundPng != null) _backgroundSaved = true;
    if (lineArtPng != null) _lineArtSaved = true;
    everSaved = true;
    controller.dirty = false;
    // A real, saved, non-empty picture counts as "finished" for the
    // sticker rewards (autosave makes this equivalent to having painted).
    if (controller.paintLayer != null) {
      Progress.instance.registerArtworkCompleted(artworkId);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (controller.dirty) _save();
    }
  }

  Future<void> _share() async {
    if (!await ParentalGate.show(context)) return;
    Sfx.instance.tada();
    await share_util.shareArtwork(
      width: kCanvasWidth,
      height: kCanvasHeight,
      background: controller.backgroundImage,
      paintLayer: controller.paintLayer,
      lineArt: controller.lineArt,
    );
    if (mounted) showConfetti(context);
    await countShareAndMaybeReview();
  }

  Future<void> _leave() async {
    if (controller.dirty) await _save();
    // Sticker unlock party — only on the way out, never mid-painting.
    for (final reward in Progress.instance.takeUncelebrated()) {
      if (!mounted) break;
      await _celebrateReward(reward);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _celebrateReward(StickerReward reward) async {
    Sfx.instance.tada();
    // Confetti fires from inside the reveal (above its scrim).
    await showRewardReveal(
      context,
      emoji: reward.emoji,
      title: context.l10n.rewardUnlockedTitle,
      body: context.l10n.rewardUnlockedBody,
      buttonLabel: context.l10n.rewardUnlockedOk,
    );
  }

  @override
  void dispose() {
    _autoSave?.cancel();
    _cbnHintTimer?.cancel();
    if (_isCbn) controller.lastFill.removeListener(_onCbnFill);
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    controller.dispose();
    viewport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: PixieGradients.canvasBg),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: loading
                  ? KeyedSubtree(
                      key: const ValueKey('loading'),
                      child: _buildLoading(),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('canvas'),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final portrait =
                              constraints.maxWidth < constraints.maxHeight;
                          return portrait
                              ? _buildPortrait()
                              : _buildLandscape();
                        },
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// While rasterizing a bundled page, show it as a sheet of paper — the
  /// Hero flight from the picker tile lands here, hiding the load time.
  Widget _buildLoading() {
    final page = widget.page;
    if (page == null) {
      return Center(child: LoadingPixie(label: context.l10n.canvasLoading));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AspectRatio(
          aspectRatio: kCanvasWidth / kCanvasHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: PixiePalette.ink.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Hero(
              tag: page.id,
              child: SvgPicture.asset(page.assetPath, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscape() {
    final rail = _LeftRail(
      controller: controller,
      showFill: traceId == null,
      fillOnly: _isCbn,
      onBack: _leave,
      onShare: _share,
    );
    final canvasArea = Expanded(child: _canvasArea(portrait: false));
    // Left-handed kids get the rail on the right, out of the drawing arm's
    // way.
    final leftHanded = Settings.instance.leftHanded;
    return Column(
      children: [
        Expanded(
          child: Row(
            children:
                leftHanded ? [canvasArea, rail] : [rail, canvasArea],
          ),
        ),
        SizedBox(height: 76, child: _palette()),
      ],
    );
  }

  Widget _palette() {
    final spec = _cbnSpec;
    if (spec == null) return ColorPalette(controller: controller);
    return CbnPalette(
      spec: spec,
      selectedNumber: _cbnSelected,
      doneNumbers: _cbnDoneNumbers,
      hintNumber: _cbnHint,
      onSelect: _selectCbnNumber,
    );
  }

  Widget _buildPortrait() {
    return Column(
      children: [
        Expanded(child: _canvasArea(portrait: true)),
        Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: PixiePalette.grape.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: ToolBarRail(
              controller: controller,
              direction: Axis.horizontal,
              showFill: traceId == null,
              fillOnly: _isCbn,
            ),
          ),
        ),
        SizedBox(height: 76, child: _palette()),
      ],
    );
  }

  Widget _canvasArea({required bool portrait}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          // The canvas as a sheet of "paper": rounded, softly shadowed.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: PixiePalette.ink.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CanvasViewport(
                viewport: viewport,
                controller: controller,
                child: PaintingCanvas(controller: controller),
              ),
            ),
          ),
          if (portrait) ...[
            Positioned(
              top: 8,
              left: Settings.instance.leftHanded ? null : 8,
              right: Settings.instance.leftHanded ? 8 : null,
              child: _RoundButton(
                icon: Icons.arrow_back_rounded,
                tooltip: context.l10n.back,
                onTap: _leave,
              ),
            ),
            Positioned(
              top: 8,
              left: Settings.instance.leftHanded ? 60 : null,
              right: Settings.instance.leftHanded ? null : 60,
              child: _RoundButton(
                icon: Icons.ios_share_rounded,
                tooltip: context.l10n.shareForParents,
                onTap: _share,
              ),
            ),
          ],
          Positioned(
            top: 8,
            left: Settings.instance.leftHanded ? 8 : null,
            right: Settings.instance.leftHanded ? null : 8,
            child: ListenableBuilder(
              listenable: viewport,
              builder: (context, _) {
                final zoomed = viewport.isZoomed;
                // Always mounted: pops in with overshoot, shrinks out fast.
                return IgnorePointer(
                  ignoring: !zoomed,
                  child: AnimatedOpacity(
                    opacity: zoomed ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedScale(
                      scale: zoomed ? 1 : 0.3,
                      duration: const Duration(milliseconds: 250),
                      curve: zoomed ? Curves.easeOutBack : Curves.easeIn,
                      child: _RoundButton(
                        icon: Icons.fit_screen_rounded,
                        tooltip: context.l10n.resetView,
                        onTap: viewport.reset,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Confirmation chip after a tool change (emoji carries the info
          // for kids who can't read yet).
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(child: _ToolChip(controller: controller)),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.7, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: child,
                ),
              ),
              child: controller.isFilling
                  ? const Align(
                      key: ValueKey('filling'),
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: 56),
                        child: LoadingPixie(emoji: '🪣'),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('idle')),
            ),
          ),
        ],
      ),
    );
  }
}

/// White round floating sticker button used for the canvas overlays.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StickerCircleButton(
      icon: icon,
      tooltip: tooltip,
      onTap: onTap,
      accent: PixiePalette.grape,
    );
  }
}

/// Floating pill that briefly confirms a tool change ("🖌️ Pinsel"), then
/// fades out.
class _ToolChip extends StatefulWidget {
  const _ToolChip({required this.controller});

  final CanvasController controller;

  @override
  State<_ToolChip> createState() => _ToolChipState();
}

class _ToolChipState extends State<_ToolChip> {
  late ToolKind _lastTool = widget.controller.tool;
  late String _lastStamp = widget.controller.stampEmoji;
  late ShapeKind _lastShape = widget.controller.shapeKind;
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  void _onChange() {
    final tool = widget.controller.tool;
    final stamp = widget.controller.stampEmoji;
    final shape = widget.controller.shapeKind;
    if (tool == _lastTool && stamp == _lastStamp && shape == _lastShape) {
      return;
    }
    _lastTool = tool;
    _lastStamp = stamp;
    _lastShape = shape;
    _timer?.cancel();
    setState(() => _visible = true);
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, -0.4),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: PixieTokens.softShadow(PixiePalette.grape),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                toolEmoji(
                  _lastTool,
                  stampEmoji: _lastStamp,
                  shapeEmoji: shapes.shapeEmoji(_lastShape),
                ),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                toolLabel(context, _lastTool),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftRail extends StatelessWidget {
  const _LeftRail({
    required this.controller,
    required this.onBack,
    required this.onShare,
    this.showFill = true,
    this.fillOnly = false,
  });

  final CanvasController controller;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final bool showFill;
  final bool fillOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: PixiePalette.grape.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Tooltip(
            message: context.l10n.back,
            child: Bouncy(
              onTap: onBack,
              child: Icon(
                Icons.arrow_back_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ToolBarRail(
              controller: controller,
              showFill: showFill,
              fillOnly: fillOnly,
            ),
          ),
          Tooltip(
            message: context.l10n.shareForParents,
            child: Bouncy(
              onTap: onShare,
              child: Icon(
                Icons.ios_share_rounded,
                size: 26,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
