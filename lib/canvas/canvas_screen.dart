import 'dart:async';
import '../ui/celebrate.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

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
import '../ui/hero_tags.dart';
import '../ui/kid_dialog.dart';
import '../ui/motion.dart';
import '../ui/loading_pixie.dart';
import '../ui/paper_doodles.dart';
import '../ui/paper_sheet.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../models/reward.dart';
import '../trace/trace_session.dart';
import '../trace/trace_template.dart';
import '../ui/reward_reveal.dart';
import '../util/image_io.dart';
import '../util/profiles.dart';
import '../util/progress.dart';
import '../util/review.dart';
import '../util/settings.dart';
import '../util/sfx.dart';
import '../util/share.dart' as share_util;
import '../util/svg_raster.dart';
import '../widgets/cbn_palette.dart';
import '../widgets/color_palette.dart';
import '../widgets/parental_gate.dart';
import '../widgets/shape_picker.dart' as shapes;
import '../widgets/tool_bar.dart';
import 'canvas_controller.dart';
import 'canvas_viewport.dart';
import 'cbn_session.dart';
import 'fill_pattern.dart';
import 'painting_canvas.dart';
import 'pause_curtain.dart';
import 'region_label.dart';
import 'save_session.dart';
import 'stroke.dart';

const int kCanvasWidth = 2048;
const int kCanvasHeight = 1536;

/// Height reserved for the floating controls when the picture would
/// otherwise fill its area edge to edge.
const double kCanvasControlBand = 56;

/// Where the paper actually lies inside an area of [area].
///
/// The picture is always 4:3 and the viewport letterboxes it, so on a phone
/// held upright there is a wide empty band above and below it. Until v8.7
/// the white sheet was painted across the *whole* area, which made that band
/// look like paper — so Back and Share sat on it (drawing near the top of
/// the picture left the screen or opened the parental gate), and a tap in it
/// still painted, clamped into a hard line down the edge of the picture.
///
/// Sizing the sheet to the picture turns the band into a real margin: the
/// controls get somewhere to live that is not the drawing, at no cost to the
/// paper — it was never larger than this. [reserveTop] is for the one case
/// where the area is itself about 4:3 and there is no band to borrow; then
/// the picture does give up a strip, because a control over the drawing is
/// worse than a slightly smaller drawing.
Rect paperRect(Size area, {double reserveTop = 0}) {
  final height = math.max(0.0, area.height - reserveTop);
  final scale = math.min(area.width / kCanvasWidth, height / kCanvasHeight);
  final w = kCanvasWidth * scale;
  final h = kCanvasHeight * scale;
  return Rect.fromLTWH(
    (area.width - w) / 2,
    reserveTop + (height - h) / 2,
    w,
    h,
  );
}

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
  TraceSession? _trace;

  // Color-by-number: all the rules live in the session, the screen only
  // renders them and owns the transient hint highlight.
  CbnSession? _cbn;
  final Set<int> _resumedCbnRegions = {};
  int? _cbnHint;
  Timer? _cbnHintTimer;
  bool _cbnCelebrated = false;
  bool get _isCbn => _cbn != null;
  late bool hasPhoto;
  late bool hasPhotoLineArt;
  bool loading = true;

  /// Owns the whole save pipeline — see [ArtworkSaveSession].
  late final ArtworkSaveSession _saves;
  Timer? _autoSave;

  /// Fires the painting-break curtain; null when a parent left it off.
  Timer? _pause;

  /// Decided once, at entry: the nudge marks itself as seen the moment it
  /// appears, so re-reading the setting on the next build would yank it off
  /// the screen again.
  late bool _rotateHintPending = !Settings.instance.rotateHintSeen;

  /// The active child's toolbar size, read once when the picture opens —
  /// swapping the toolbar under a drawing hand would be worse than waiting
  /// for the next picture.
  late final bool _simpleTools = ProfileStore.instance.active.simpleTools;

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
    _saves = ArtworkSaveSession(
      controller: controller,
      artworkId: artworkId,
      width: kCanvasWidth,
      height: kCanvasHeight,
      hasPhoto: hasPhoto,
      hasPhotoLineArt: hasPhotoLineArt,
      pageId: pageId,
      traceId: traceId,
      sceneId: sceneId,
      cbnFilled: () => _cbnFilledForSave,
      resumed: widget.resume != null,
    );
    // A tool the simple toolbar does not show would be unselectable and
    // unchangeable — the child would be stuck with it.
    if (_simpleTools && !kSimpleTools.contains(controller.tool)) {
      controller.selectTool(ToolKind.brush);
    }
    _load();
    _autoSave = Timer.periodic(const Duration(seconds: 30), (_) {
      if (controller.dirty) _saves.save();
    });
    _startPauseTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Loads whatever the chosen mode needs. Every step is guarded twice: a
  /// `mounted` check after each await (the screen can be left mid-load, and
  /// handing an image to a disposed controller double-frees it), and a
  /// try/catch around the whole thing so a damaged file shows an empty
  /// canvas instead of an eternal loading pixie.
  Future<void> _load() async {
    try {
      await _loadLayers();
    } catch (_) {
      // Broken or half-written file — start from a blank canvas rather
      // than leaving the kid stuck on the loading screen.
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadLayers() async {
    if (traceId != null) {
      await _loadTrace(traceId!);
      if (!mounted) return;
    }
    if (pageId != null) {
      final page = await ColoringPage.byId(pageId!);
      if (!mounted) return;
      if (page != null) {
        final art = await rasterizeSvgAsset(
          page.assetPath,
          kCanvasWidth,
          kCanvasHeight,
        );
        if (!mounted) return art.dispose();
        controller.setLineArt(art);
        if (page.isColorByNumber) await _loadCbn(page);
        if (!mounted) return;
      }
    }
    if (widget.photoLineArt != null) {
      controller.setLineArt(widget.photoLineArt!);
    } else if ((widget.resume?.hasPhotoLineArt ?? false) &&
        await widget.resume!.lineArtFile.exists()) {
      final art =
          await lineArtFromPng(await widget.resume!.lineArtFile.readAsBytes());
      if (!mounted) return art.dispose();
      controller.setLineArt(art);
    }
    final photoPath = widget.photoPath;
    if (widget.scene != null) {
      final image = await rasterizeSvgToImage(
          widget.scene!.assetPath, kCanvasWidth, kCanvasHeight);
      if (!mounted) return image.dispose();
      controller.setBackground(image);
    } else if (photoPath != null) {
      final bytes = await File(photoPath).readAsBytes();
      final image = await normalizePhoto(bytes, kCanvasWidth, kCanvasHeight);
      if (!mounted) return image.dispose();
      controller.setBackground(image);
    } else if ((widget.resume?.hasPhoto ?? false) &&
        await widget.resume!.backgroundFile.exists()) {
      final bytes = await widget.resume!.backgroundFile.readAsBytes();
      final image = await pngBytesToImage(bytes);
      if (!mounted) return image.dispose();
      controller.setBackground(image);
    }
    final resume = widget.resume;
    if (resume != null && await resume.paintFile.exists()) {
      final bytes = await resume.paintFile.readAsBytes();
      final image = await pngBytesToImage(bytes);
      if (!mounted) return image.dispose();
      controller.setPaintLayer(image);
    }
    if (resume != null) {
      if (await resume.opsFile.exists()) {
        final source = await resume.opsFile.readAsString();
        if (!mounted) return;
        controller.loadOps(decodeOps(source));
      } else if (controller.paintLayer != null) {
        // Legacy artwork painted before the op log existed — recording now
        // would tell a story that misses everything already on the canvas.
        controller.recordOps = false;
      }
    }
  }

  /// Builds the trace guide and wires the commit hook. The guide is
  /// regenerated from the template id — nothing rasterized is persisted.
  Future<void> _loadTrace(String id) async {
    final session = await TraceSession.create(
      templateId: id,
      width: kCanvasWidth,
      height: kCanvasHeight,
      alreadyCompleted: Progress.instance.completedTraceIds.contains(id),
    );
    if (session == null) return;
    if (!mounted) return session.guide.dispose();
    _trace = session;
    controller.setTraceGuide(session.guide);
    controller.onStrokeCommitted = _onTraceStroke;
    _showModeIntro(
      seen: Settings.instance.traceIntroSeen,
      mark: Settings.instance.markTraceIntroSeen,
      emoji: '✏️',
      title: (l10n) => l10n.traceIntroTitle,
      body: (l10n) => l10n.traceIntroBody,
    );
  }

  /// Color-by-number setup: labels the enclosed regions of the rasterized
  /// line art (isolate), maps each sidecar label to its region id, restores
  /// already-solved regions and wires the fill guard.
  Future<void> _loadCbn(ColoringPage page) async {
    // Restore first, unconditionally: if anything below fails (missing
    // sidecar, renamed page) the very next autosave would otherwise write
    // an empty cbnFilled and wipe a half-solved picture for good.
    _resumedCbnRegions.addAll(widget.resume?.cbnFilled ?? const []);
    final spec = await CbnSpec.load(page.id);
    final alpha = controller.barrierAlpha;
    if (spec == null || alpha == null || !mounted) return;
    const w = kCanvasWidth, h = kCanvasHeight;
    final regionOf = await Isolate.run(() => labelRegions(alpha, w, h));
    if (!mounted) return;
    final session = CbnSession.fromLabels(
      spec: spec,
      regionOf: regionOf,
      width: w,
      height: h,
      alreadyFilled: _resumedCbnRegions,
    );
    _cbn = session;
    _cbnCelebrated = session.isComplete ||
        Progress.instance.completedCbnIds.contains(page.id);
    controller
      ..tool = ToolKind.fill
      ..fillPattern = FillPattern.solid
      ..fillGuard = _cbnFillGuard
      ..lastFill.addListener(_onCbnFill);
    controller.selectCbnColor(spec.colorOf[session.selected]!);
    controller.setCbnLabels(session.labels());
    _showModeIntro(
      seen: Settings.instance.cbnIntroSeen,
      mark: Settings.instance.markCbnIntroSeen,
      emoji: '🔢',
      title: (l10n) => l10n.cbnIntroTitle,
      body: (l10n) => l10n.cbnIntroBody,
    );
  }

  /// The one-time card that says what the rules are, for the two modes that
  /// have any.
  ///
  /// Only ever for those two — never for free painting. Its modal barrier
  /// would sit over the very things the reach and text-scale tests measure,
  /// and there is nothing to explain there anyway.
  ///
  /// Posted after the frame because the loader that calls this is still
  /// building the screen underneath.
  void _showModeIntro({
    required bool seen,
    required Future<void> Function() mark,
    required String emoji,
    required String Function(AppLocalizations) title,
    required String Function(AppLocalizations) body,
  }) {
    if (seen) return;
    unawaited(mark());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(showKidNotice(
        context,
        emoji: emoji,
        title: title(context.l10n),
        body: body(context.l10n),
        okLabel: context.l10n.okAction,
      ));
    });
  }

  /// Regions to persist: the live session once it exists, otherwise the
  /// values we resumed with (so a failed setup never erases them).
  List<int> get _cbnFilledForSave =>
      (_cbn?.filledRegions ?? _resumedCbnRegions).toList();

  void _selectCbnNumber(int n) {
    final session = _cbn;
    final color = session?.spec.colorOf[n];
    if (session == null || color == null) return;
    session.select(n);
    setState(() {});
    controller.selectCbnColor(color);
    Sfx.instance.tick();
  }

  bool _cbnFillGuard(Offset pos) {
    final session = _cbn;
    if (session == null) return true;
    final verdict = session.tapAt(pos);
    if (verdict.allowed) return true;
    // Never punitive: a soft tick, and from the second miss on the right
    // swatch pulses to show where to look.
    Sfx.instance.tick();
    if (verdict.showHint) {
      _cbnHintTimer?.cancel();
      setState(() => _cbnHint = verdict.correctNumber);
      _cbnHintTimer = Timer(PixieMotion.dwell, () {
        if (mounted) setState(() => _cbnHint = null);
      });
    }
    return false;
  }

  void _onCbnFill() {
    final pos = controller.lastFill.value;
    final session = _cbn;
    if (pos == null || session == null) return;
    final result = session.registerFill(pos);
    if (!result.counted) return;
    controller.setCbnLabels(session.labels());
    if (result.nextSelection != null) {
      controller.selectCbnColor(session.spec.colorOf[result.nextSelection]!);
    }
    setState(() {});
    if (result.completed && !_cbnCelebrated) {
      _cbnCelebrated = true;
      Progress.instance.registerCbnCompleted(pageId!);
      if (mounted) celebrate(context);
    }
  }

  void _onTraceStroke(Stroke stroke) {
    if (_trace?.registerStroke(stroke) != true) return;
    Progress.instance.registerTraceCompleted(traceId!);
    if (mounted) celebrate(context);
  }

  /// Arms the painting-break curtain, if a parent asked for one.
  ///
  /// The picture is saved first, so the break can never cost anything, and
  /// the timer re-arms afterwards — a session that carries on gets the same
  /// reminder again rather than one per screen visit.
  void _startPauseTimer() {
    _pause?.cancel();
    final minutes = Settings.instance.pauseAfterMinutes;
    if (minutes <= 0) return;
    _pause = Timer(Duration(minutes: minutes), () async {
      if (!mounted) return;
      if (controller.dirty) await _saves.save();
      if (!mounted) return;
      await showPauseCurtain(context);
      if (mounted) _startPauseTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (controller.dirty) _saves.save();
    }
    // `paused` only — `inactive` also fires for a passing notification
    // shade, and throwing the undo history away because a message arrived
    // would be its own kind of bug. Ordering matters: the save above is
    // queued first, so it still reads the layers it needs.
    if (state == AppLifecycleState.paused) {
      controller.releaseMemory();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
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
    if (mounted) celebrate(context, level: Celebration.nod, sound: false);
    await countShareAndMaybeReview();
  }

  Future<void> _leave() async {
    if (controller.dirty) await _saves.save();
    if (_saves.saveFailed && mounted && !await _confirmLeaveUnsaved()) return;
    // Sticker unlock party — only on the way out, never mid-painting.
    for (final reward in Progress.instance.takeUncelebrated()) {
      if (!mounted) break;
      await _celebrateReward(reward);
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// The save failed and the picture is only in memory — leaving now loses
  /// it. Worded for the parent who will be handed the tablet, and offering
  /// the retry first, because freeing storage in another app and coming back
  /// is the fix.
  ///
  /// It used to retry forever: a modal that could not be dismissed, under a
  /// `PopScope` that would not pop, inside a `while (true)`. If the storage
  /// stayed full the child was simply kept on this screen, and the only way
  /// out was a grey word they could not read. So the loop counts, and after
  /// the second failure "leave anyway" stops being the quiet option and
  /// becomes a real button — by then retrying is not what is going to work.
  static const int _saveRetries = 2;

  Future<bool> _confirmLeaveUnsaved() async {
    for (var attempt = 0;; attempt++) {
      if (!mounted) return false;
      final givingUp = attempt >= _saveRetries;
      final retry = await showKidDialog<bool>(
        context: context,
        barrierDismissible: false,
        emoji: '💾',
        title: context.l10n.saveFailedTitle,
        body: Text(
          context.l10n.saveFailedBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: (pop) => [
          if (givingUp)
            KidDialogButton(
              label: context.l10n.saveFailedLeave,
              emoji: '👋',
              onTap: () => Navigator.pop(pop, false),
            )
          else ...[
            KidDialogButton(
              label: context.l10n.saveFailedRetry,
              emoji: '🔄',
              onTap: () => Navigator.pop(pop, true),
            ),
            KidDialogTextButton(
              label: context.l10n.saveFailedLeave,
              onTap: () => Navigator.pop(pop, false),
            ),
          ],
        ],
      );
      if (retry != true) return true;
      await _saves.save();
      if (!_saves.saveFailed) return true;
    }
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
    _pause?.cancel();
    _cbnHintTimer?.cancel();
    controller.lastFill.removeListener(_onCbnFill);
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // A save in flight still reads the layers — free them only afterwards,
    // otherwise it encodes disposed images. The controller isn't part of
    // the element tree, so outliving this State briefly is safe.
    final pending = _saves.pending;
    if (pending != null) {
      pending.whenComplete(controller.dispose);
    } else {
      controller.dispose();
    }
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
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: PixieGradients.canvasBg),
          // The same doodled paper as every other screen — but standing
          // still and fainter. A drifting mark behind a drawing hand is
          // exactly what a child painting a line does not need, so this
          // painter has no ticker at all: one fixed phase, painted once,
          // behind everything.
          child: CustomPaint(
            painter: const DoodlePainter(0.12, alpha: 0.04),
            child: SafeArea(
            child: AnimatedSwitcher(
              duration: PixieMotion.select,
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
      ),
    );
  }

  /// While the picture is being prepared, show it as a sheet of paper — the
  /// Hero flight from the tile that was tapped lands here, hiding the load
  /// time.
  ///
  /// All three ways in that *have* a picture to fly get one: a bundled
  /// coloring page, a saved picture being resumed, a scene. Free drawing,
  /// photos and tracing start from a tile with nothing to carry over, so
  /// they get the hopping brush instead.
  Widget _buildLoading() {
    final page = widget.page;
    final resume = widget.resume;
    final scene = widget.scene;

    final Widget? preview = switch ((page, resume, scene)) {
      (final ColoringPage p, _, _) => Hero(
          tag: pageHeroTag(p.id),
          flightShuttleBuilder: pixieHeroShuttle,
          child: SvgPicture.asset(p.assetPath, fit: BoxFit.contain),
        ),
      (_, final Artwork a, _) when a.thumbFile.existsSync() => Hero(
          tag: artworkHeroTag(a.id),
          flightShuttleBuilder: pixieHeroShuttle,
          child: Image.file(
            a.thumbFile,
            fit: BoxFit.cover,
            // Same reason as in the gallery tile: thumbnails change on disk
            // under the same path, so a cached one would be stale.
            key: ValueKey(a.updatedAt),
            cacheWidth: 560,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      (_, _, final Scene s) => Hero(
          tag: sceneHeroTag(s.id),
          flightShuttleBuilder: pixieHeroShuttle,
          child: SvgPicture.asset(s.assetPath, fit: BoxFit.cover),
        ),
      _ => null,
    };
    if (preview == null) {
      return Center(child: LoadingPixie(label: context.l10n.canvasLoading));
    }
    return PaperSheet(
      aspectRatio: kCanvasWidth / kCanvasHeight,
      child: preview,
    );
  }

  Widget _buildLandscape() {
    final rail = _LeftRail(
      controller: controller,
      showFill: traceId == null,
      fillOnly: _isCbn,
      simple: _simpleTools,
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
        SizedBox(height: kPaletteHeight, child: _palette()),
      ],
    );
  }

  Widget _palette() {
    final session = _cbn;
    if (session == null) return ColorPalette(controller: controller);
    return CbnPalette(
      spec: session.spec,
      selectedNumber: session.selected,
      doneNumbers: session.doneNumbers,
      hintNumber: _cbnHint,
      onSelect: _selectCbnNumber,
    );
  }

  /// Portrait toolbar: the tools scroll, undo and redo do not.
  ///
  /// The cluster sits on the side the drawing hand is *not* on, mirroring
  /// the floating buttons above the canvas.
  Widget _buildPortrait() {
    final leftHanded = Settings.instance.leftHanded;
    final tools = Expanded(
      child: ToolBarRail(
        controller: controller,
        direction: Axis.horizontal,
        showFill: traceId == null,
        fillOnly: _isCbn,
        buttonSize: 50,
        simple: _simpleTools,
      ),
    );
    final actions = ToolActionCluster(
      controller: controller,
      direction: Axis.horizontal,
    );
    return Column(
      children: [
        Expanded(child: _canvasArea(portrait: true)),
        Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: PixieTokens.barDecoration(),
          child: Row(
            children: leftHanded ? [actions, tools] : [tools, actions],
          ),
        ),
        SizedBox(height: kPaletteHeight, child: _palette()),
      ],
    );
  }

  Widget _canvasArea({required bool portrait}) {
    // Read once: the floating buttons all mirror on the same setting, and
    // five separate reads in one build could in principle disagree.
    final leftHanded = Settings.instance.leftHanded;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final area = Size(constraints.maxWidth, constraints.maxHeight);
          var paper = paperRect(area);
          // Upright there is almost always a band to borrow; an area that is
          // itself about 4:3 is the one case where the picture has to give a
          // strip up rather than wear its controls.
          if (portrait && paper.top < kCanvasControlBand) {
            paper = paperRect(area, reserveTop: kCanvasControlBand);
          }
          // Above the picture upright, beside it on its side. Only if the
          // margin is genuinely big enough — a control half on the paper
          // would be the problem all over again.
          final aboveFits = paper.top >= kCanvasControlBand;
          final besideFits = paper.left >= kCanvasControlBand;
          final rowTop = aboveFits ? paper.top - 52 : 8.0;
          // Distance from the area's edge to the paper's, on whichever side
          // this child's hand is not.
          final nearEdge = leftHanded ? area.width - paper.right : paper.left;
          final inset = besideFits && !aboveFits ? (nearEdge - 52).clamp(0.0, 8.0) : 8.0;

          return Stack(
            children: [
              // The canvas as a sheet of "paper": rounded, softly shadowed.
              // Exactly the picture's shape, so everything outside it is
              // margin rather than something that looks drawable.
              Positioned.fromRect(
                rect: paper,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(PixieTokens.rTile),
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
              // Phones only: the pictures are 4:3 across, so upright the
              // paper uses barely half the height. Tablets are wide enough
              // either way. It sits in the band *below* the picture, where
              // its dismiss tap cannot swallow the start of a stroke.
              if (portrait &&
                  _rotateHintPending &&
                  MediaQuery.sizeOf(context).shortestSide < 600)
                Positioned(
                  top: area.height - paper.bottom >= 44
                      ? paper.bottom + 6
                      : null,
                  bottom: area.height - paper.bottom >= 44 ? null : 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _RotateHint(
                      onDone: () {
                        if (mounted) setState(() => _rotateHintPending = false);
                      },
                    ),
                  ),
                ),
              if (portrait) ...[
                Positioned(
                  top: rowTop,
                  left: leftHanded ? null : inset,
                  right: leftHanded ? inset : null,
                  child: StickerCircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: context.l10n.back,
                    onTap: _leave,
                    accent: PixiePalette.grape,
                  ),
                ),
                Positioned(
                  top: rowTop,
                  left: leftHanded ? null : inset + 52,
                  right: leftHanded ? inset + 52 : null,
                  child: StickerCircleButton(
                    icon: Icons.ios_share_rounded,
                    tooltip: context.l10n.shareForParents,
                    onTap: _share,
                    accent: PixiePalette.grape,
                  ),
                ),
              ],
              Positioned(
                top: rowTop,
                left: leftHanded ? inset : null,
                right: leftHanded ? null : inset,
                child: ListenableBuilder(
                  listenable: viewport,
                  builder: (context, _) {
                    final zoomed = viewport.isZoomed;
                    // Always mounted: pops in with overshoot, shrinks out
                    // fast.
                    return IgnorePointer(
                      ignoring: !zoomed,
                      child: AnimatedOpacity(
                        opacity: zoomed ? 1 : 0,
                        duration: PixieMotion.select,
                        child: AnimatedScale(
                          scale: zoomed ? 1 : 0.3,
                          duration: PixieMotion.select,
                          curve:
                              zoomed ? PixieCurves.spring : PixieCurves.exit,
                          child: StickerCircleButton(
                            icon: Icons.fit_screen_rounded,
                            tooltip: context.l10n.resetView,
                            onTap: viewport.reset,
                            accent: PixiePalette.grape,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Confirmation chip after a tool change (emoji carries the
              // info for kids who can't read yet). It takes no pointers, so
              // it may sit over the picture.
              Positioned(
                top: paper.top + 12,
                left: 0,
                right: 0,
                child: Center(
                  child: IgnorePointer(child: _ToolChip(controller: controller)),
                ),
              ),
              Positioned.fromRect(
                rect: paper,
                child: IgnorePointer(
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => AnimatedSwitcher(
                      duration: PixieMotion.select,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.7, end: 1.0).animate(
                            CurvedAnimation(
                                parent: anim, curve: PixieCurves.spring),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The one-time "turn me sideways" nudge.
///
/// Shown once ever, on a phone, in portrait. It writes its own seen-flag the
/// moment it appears — a hint the app was killed underneath still counts as
/// shown — waits six seconds and fades away; a tap ends it sooner. Nothing
/// here blocks painting: the pill sits below the paper's centre and hands
/// its touches on once it is gone.
class _RotateHint extends StatefulWidget {
  const _RotateHint({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_RotateHint> createState() => _RotateHintState();
}

class _RotateHintState extends State<_RotateHint> {
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Deferred: the setting notifies its listeners synchronously, and this
    // runs while the canvas is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(Settings.instance.markRotateHintSeen());
    });
    _timer = Timer(PixieMotion.dwellLong, _dismiss);
  }

  void _dismiss() {
    if (!mounted || !_visible) return;
    setState(() => _visible = false);
    _timer?.cancel();
    _timer = Timer(PixieMotion.select, () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: PixieMotion.select,
      child: Bouncy(
        onTap: _dismiss,
        playTick: false,
        semanticLabel: context.l10n.rotateHint,
        child: StickerPill(
          margin: const EdgeInsets.symmetric(horizontal: PixieTokens.gapXl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔄', style: TextStyle(fontSize: 22)),
              const SizedBox(width: PixieTokens.gapSmall),
              Flexible(
                child: Text(
                  context.l10n.rotateHint,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
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
    _timer = Timer(PixieMotion.dwell, () {
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
      duration: PixieMotion.select,
      curve: PixieCurves.spring,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: PixieMotion.select,
        child: StickerPill(
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
              const SizedBox(width: PixieTokens.gapSmall),
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
    this.simple = false,
  });

  final CanvasController controller;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final bool showFill;
  final bool fillOnly;
  final bool simple;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      margin: const EdgeInsets.all(8),
      decoration: PixieTokens.barDecoration(),
      child: Column(
        children: [
          const SizedBox(height: PixieTokens.gapTiny),
          Tooltip(
            message: context.l10n.back,
            child: Bouncy(
              onTap: onBack,
              // A tooltip is not a name a screen reader announces — sideways
              // these two are the only controls not built from
              // [StickerCircleButton], which passes its tooltip on for them.
              semanticLabel: context.l10n.back,
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
              simple: simple,
            ),
          ),
          // Outside the scrolling rail above — see [ToolActionCluster].
          ToolActionCluster(controller: controller),
          Tooltip(
            message: context.l10n.shareForParents,
            child: Bouncy(
              onTap: onShare,
              semanticLabel: context.l10n.shareForParents,
              child: Icon(
                Icons.ios_share_rounded,
                size: 26,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: PixieTokens.gapTiny),
        ],
      ),
    );
  }
}
