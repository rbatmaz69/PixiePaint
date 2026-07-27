import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/tool.dart';
import '../ui/app_theme.dart';
import '../ui/motion.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/pixie_palette.dart';
import '../ui/pop_in.dart';
import '../util/color_utils.dart';
import 'fill_pattern_picker.dart';
import 'shape_picker.dart' as shapes;
import 'size_picker.dart';
import 'stamp_picker.dart';
import 'symmetry_picker.dart' as symmetry;

/// Accent color per tool — used for the selected highlight so every tool
/// feels like its own little character. Harmonized with the PixiePalette.
Color toolAccent(ToolKind tool) => switch (tool) {
  ToolKind.brush => PixiePalette.grape,
  ToolKind.marker => PixiePalette.sky,
  ToolKind.crayon => PixiePalette.tangerine,
  ToolKind.rainbow => PixiePalette.berry,
  ToolKind.glitter => PixiePalette.bubblegum,
  ToolKind.neon => PixiePalette.amber,
  ToolKind.trail => PixiePalette.raspberry,
  ToolKind.dotted => PixiePalette.indigo,
  ToolKind.twin => PixiePalette.teal,
  ToolKind.eraser => PixiePalette.slate,
  ToolKind.fill => PixiePalette.jade,
  ToolKind.stamp => PixiePalette.amber,
  ToolKind.eyedropper => PixiePalette.pine,
  ToolKind.shape => PixiePalette.periwinkle,
};

/// Emoji per tool — carries the meaning for kids who can't read yet.
String toolEmoji(
  ToolKind tool, {
  String stampEmoji = '⭐',
  String shapeEmoji = '💜',
}) => switch (tool) {
  ToolKind.brush => '🖌️',
  ToolKind.marker => '🖊️',
  ToolKind.crayon => '🖍️',
  ToolKind.rainbow => '🌈',
  ToolKind.glitter => '✨',
  ToolKind.neon => '⚡',
  ToolKind.trail => '💞',
  ToolKind.dotted => '🔵',
  ToolKind.twin => '🛤️',
  ToolKind.eraser => '🧽',
  ToolKind.fill => '🪣',
  ToolKind.stamp => stampEmoji,
  ToolKind.eyedropper => '💧',
  ToolKind.shape => shapeEmoji,
};

String toolLabel(BuildContext context, ToolKind tool) => switch (tool) {
  ToolKind.brush => context.l10n.toolBrush,
  ToolKind.marker => context.l10n.toolMarker,
  ToolKind.crayon => context.l10n.toolCrayon,
  ToolKind.rainbow => context.l10n.toolRainbow,
  ToolKind.glitter => context.l10n.toolGlitter,
  ToolKind.neon => context.l10n.toolNeon,
  ToolKind.trail => context.l10n.toolTrail,
  ToolKind.dotted => context.l10n.toolDotted,
  ToolKind.twin => context.l10n.toolTwin,
  ToolKind.eraser => context.l10n.toolEraser,
  ToolKind.fill => context.l10n.toolFill,
  ToolKind.stamp => context.l10n.toolSticker,
  ToolKind.eyedropper => context.l10n.toolEyedropper,
  ToolKind.shape => context.l10n.toolShapes,
};

/// The shell every toolbar button that can be *picked* wears: a tooltip, a
/// bouncy tap target, and a container that grows a white fill, an accent
/// border and a soft shadow when it is the chosen one. Unselected it is a
/// bare circle; selected it squares off into a rounded tile.
///
/// The glow used to be a third shadow formula living here, written to dodge
/// the negative-blur crash that [Curves.easeOutBack] causes when a shadow is
/// tweened against nothing. [PixieTokens.softShadow] has handled that at the
/// source since v8.6 — a shadow that is sometimes absent is faded out, not
/// left off — so this now uses the same one as everything else.
///
/// The tools and the magic mirror carried two copies of this, identical
/// down to the timing and the scale. Only what sits inside differs, so
/// only that is passed in.
class _PickableButton extends StatelessWidget {
  const _PickableButton({
    required this.label,
    required this.accent,
    required this.selected,
    required this.size,
    required this.onTap,
    required this.child,
  });

  final String label;
  final Color accent;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  /// Scaled and faded by the selection — pass the plain content.
  final Widget child;

  /// How much the unselected state is dimmed. The tools stay legible
  /// (0.75); the mirror goes further (0.4), because "off" is a real state
  /// there rather than just "not this one".
  static const double toolRestOpacity = 0.75;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      // The label is handed to Bouncy instead, which announces it together
      // with the selected state; leaving it here too would read it twice.
      excludeFromSemantics: true,
      child: Bouncy(
        onTap: onTap,
        playTick: false,
        semanticLabel: label,
        semanticSelected: selected,
        child: AnimatedContainer(
          duration: PixieMotion.select,
          curve: PixieCurves.spring,
          width: size,
          height: size,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius:
                BorderRadius.circular(selected ? PixieTokens.rTile : size / 2),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 2.5,
            ),
            boxShadow:
                PixieTokens.softShadow(accent, strength: selected ? 1 : 0),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Rounded pill container around one group of buttons.
///
/// [onBar] drops the fill and the shadow for the case where the pill is
/// already standing on a [PixieTokens.barDecoration] surface — both canvas
/// layouts mount it that way, and two white sheets one on top of the other
/// is a smudge, not a shape. The two-painter screen has no bar behind it,
/// so there the pill stays the white one.
///
/// Padding and margin do not change either way: the reach test measures
/// where undo lands.
Widget _pill(List<Widget> children, Axis direction, {bool onBar = false}) {
  return Container(
    margin: const EdgeInsets.all(4),
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: onBar ? Colors.transparent : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(PixieTokens.rPill),
      boxShadow: onBar ? null : PixieTokens.barShadow(),
    ),
    child: direction == Axis.vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : Row(mainAxisSize: MainAxisSize.min, children: children),
  );
}

/// Undo and redo, and nothing else. Stateful only to count its own taps —
/// see [_ToolActionClusterState].
///
/// These two live *outside* [ToolBarRail] on purpose. The rail scrolls — on
/// a 360 dp phone it shows about six of its nineteen buttons — and undo used
/// to sit at the very end of it, which put the single most important control
/// in a painting app behind a scroll gesture that nothing announced. The
/// cluster is placed by the screen and never moves.
///
/// "Clear everything" deliberately stayed *in* the rail: it is the one
/// destructive action here, it asks for confirmation anyway, and being a
/// little harder to reach suits it.
class ToolActionCluster extends StatefulWidget {
  const ToolActionCluster({
    super.key,
    required this.controller,
    this.direction = Axis.vertical,
    this.onBar = false,
    this.buttonSize = 52,
  });

  final CanvasController controller;
  final Axis direction;

  /// True where a white bar is already behind the buttons — see [_pill].
  final bool onBar;

  /// Slot width, matched to the rail beside it. Undo and redo used to be
  /// hard-wired to 48 while the tools next to them were 50 or 52, which is
  /// two pixels of drift you cannot name but can see.
  final double buttonSize;

  @override
  State<ToolActionCluster> createState() => _ToolActionClusterState();
}

class _ToolActionClusterState extends State<ToolActionCluster> {
  /// Counts *accepted* taps, and nothing else.
  ///
  /// Undoing a short stroke barely changes the picture, and a child who
  /// sees nothing happen taps again — so the button answers with a pulse.
  /// The obvious trigger, the undo stack's depth, is the wrong one: every
  /// stroke pushes onto it, and the button would twitch through the whole
  /// drawing. Counting here means only a press that actually did something
  /// moves it.
  int _undos = 0;
  int _redos = 0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _pill([
        Pulse(
          trigger: _undos,
          child: _ActionButton(
            icon: Icons.undo_rounded,
            enabled: controller.canUndo,
            size: widget.buttonSize,
            filled: true,
            label: context.l10n.undoAction,
            onTap: () {
              if (!controller.canUndo) return;
              controller.undo();
              setState(() => _undos++);
            },
          ),
        ),
        Pulse(
          trigger: _redos,
          child: _ActionButton(
            icon: Icons.redo_rounded,
            enabled: controller.canRedo,
            size: widget.buttonSize,
            filled: true,
            label: context.l10n.redoAction,
            onTap: () {
              if (!controller.canRedo) return;
              controller.redo();
              setState(() => _redos++);
            },
          ),
        ),
      ], widget.direction, onBar: widget.onBar),
    );
  }
}

class ToolBarRail extends StatefulWidget {
  const ToolBarRail({
    super.key,
    required this.controller,
    this.showFill = true,
    this.fillOnly = false,
    this.direction = Axis.vertical,
    this.buttonSize = 52,
    this.simple = false,
    this.onBar = false,
  });

  final CanvasController controller;
  final bool showFill;

  /// Color-by-number: only the bucket (plain, no pattern picker) plus
  /// clear — the numbered palette does the color choosing.
  final bool fillOnly;
  final Axis direction;

  /// The [Profile.simpleTools] toolbar: four tools, bigger, no sheets in the
  /// way. The bucket fills plainly here instead of opening the pattern
  /// picker — a child this mode is for should get paint from one tap.
  final bool simple;

  /// Edge length of one tool button. Portrait shaves a little off to give
  /// the paper more room; [Bouncy.minSize] keeps the tap target at 48.
  final double buttonSize;

  /// True where a white bar is already behind the buttons — see [_pill].
  final bool onBar;

  @override
  State<ToolBarRail> createState() => _ToolBarRailState();
}

class _ToolBarRailState extends State<ToolBarRail> {
  final ScrollController _scroll = ScrollController();

  /// One key per tool so a selection made in a sheet (stickers, shapes) can
  /// scroll its button back into view.
  final Map<ToolKind, GlobalKey> _keys = {};

  late ToolKind _lastTool = widget.controller.tool;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onToolChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onToolChanged);
    _scroll.dispose();
    super.dispose();
  }

  /// Brings the freshly selected tool into view. Deferred by a frame: the
  /// selection often arrives while a bottom sheet is still closing, and the
  /// button's context is only good once this build has run.
  void _onToolChanged() {
    final tool = widget.controller.tool;
    if (tool == _lastTool) return;
    _lastTool = tool;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _keys[tool]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: PixieMotion.select,
        curve: PixieCurves.settle,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final children = _buildGroups(context);
        return _FadeEdges(
          scroll: _scroll,
          direction: widget.direction,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: widget.direction,
            child: widget.direction == Axis.vertical
                ? Column(mainAxisSize: MainAxisSize.min, children: children)
                : Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        );
      },
    );
  }

  List<Widget> _buildGroups(BuildContext context) {
    final controller = widget.controller;
    final plainFill = widget.fillOnly || widget.simple;
    final size = widget.simple ? widget.buttonSize + 12 : widget.buttonSize;
    final tools = widget.fillOnly
        ? [ToolKind.fill]
        : widget.simple
        ? [
            for (final tool in kSimpleTools)
              if (tool != ToolKind.fill || widget.showFill) tool,
          ]
        : [
            ToolKind.brush,
            ToolKind.marker,
            ToolKind.crayon,
            ToolKind.rainbow,
            ToolKind.glitter,
            ToolKind.neon,
            ToolKind.trail,
            ToolKind.dotted,
            ToolKind.twin,
            ToolKind.stamp,
            ToolKind.shape,
            if (widget.showFill) ToolKind.fill,
            ToolKind.eyedropper,
            ToolKind.eraser,
          ];
    return [
      _pill([
        for (final tool in tools)
          _ToolButton(
            key: _keys.putIfAbsent(tool, GlobalKey.new),
            tool: tool,
            controller: controller,
            size: size,
            onTap: switch (tool) {
              ToolKind.stamp => () => showStampPicker(context, controller),
              ToolKind.shape => () => shapes.showShapePicker(
                context,
                controller,
              ),
              ToolKind.fill => plainFill
                  ? () => controller.selectTool(ToolKind.fill)
                  : () => showFillPatternPicker(context, controller),
              _ => () => controller.selectTool(tool),
            },
          ),
      ], widget.direction, onBar: widget.onBar),
      if (!widget.fillOnly)
        _pill([
          _SizeButton(
            brushSize: controller.brushSize,
            color: controller.color,
            size: size,
            onTap: () => showSizePicker(context, controller),
          ),
          // Thick or thin is half the fun and needs no reading, so the size
          // button stays. The magic mirror does not: it is a rule to grasp
          // before it is a pleasure.
          if (!widget.simple)
            _SymmetryButton(
              controller: controller,
              size: size,
              onTap: () => symmetry.showSymmetryPicker(context, controller),
            ),
        ], widget.direction, onBar: widget.onBar),
      _pill([
        _ActionButton(
          icon: Icons.delete_sweep_outlined,
          enabled: !controller.isEmpty,
          size: size,
          label: context.l10n.clearAction,
          onTap: () => _confirmClear(context, controller),
        ),
      ], widget.direction, onBar: widget.onBar),
    ];
  }
}

Future<void> _confirmClear(
    BuildContext context, CanvasController controller) async {
  final ok = await showKidDialog<bool>(
    context: context,
    emoji: '🧽',
    title: context.l10n.clearTitle,
    body: Text(context.l10n.clearBody, textAlign: TextAlign.center),
    actions: (pop) => [
      KidDialogButton(
        label: context.l10n.clearKeep,
        emoji: '🖌️',
        onTap: () => Navigator.pop(pop, false),
      ),
      KidDialogTextButton(
        label: context.l10n.clearConfirm,
        onTap: () => Navigator.pop(pop, true),
      ),
    ],
  );
  if (ok == true) controller.clearAll();
}

/// Softens the two ends of a scrolling strip, but only on the side that
/// actually has more content — a strip that fits keeps hard edges.
///
/// This is the missing half of the scroll fix: the toolbar could always be
/// scrolled, it just never said so.
class _FadeEdges extends StatefulWidget {
  const _FadeEdges({
    required this.scroll,
    required this.direction,
    required this.child,
  });

  final ScrollController scroll;
  final Axis direction;
  final Widget child;

  @override
  State<_FadeEdges> createState() => _FadeEdgesState();
}

class _FadeEdgesState extends State<_FadeEdges> {
  bool _before = false;
  bool _after = false;

  /// Always deferred a frame: metrics notifications are dispatched during
  /// layout, and calling setState there is an error.
  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final position =
          widget.scroll.hasClients ? widget.scroll.position : null;
      final before = position != null && position.extentBefore > 0.5;
      final after = position != null && position.extentAfter > 0.5;
      if (before != _before || after != _after) {
        setState(() {
          _before = before;
          _after = after;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.direction == Axis.horizontal;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _schedule();
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _schedule();
          return false;
        },
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
            end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: _before ? 0 : 1),
              Colors.white,
              Colors.white,
              Colors.white.withValues(alpha: _after ? 0 : 1),
            ],
            stops: const [0.0, 0.07, 0.93, 1.0],
          ).createShader(rect),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.tool,
    required this.controller,
    required this.onTap,
    this.size = 52,
  });

  final ToolKind tool;
  final CanvasController controller;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final selected = controller.tool == tool;
    final accent = toolAccent(tool);
    final showColorBadge =
        tool == ToolKind.brush ||
        tool == ToolKind.fill ||
        tool == ToolKind.shape;

    // The whole toolbar speaks emoji — the same language as the pickers
    // and the tool chip. Stamp/shape show their selected motif.
    final emoji = switch (tool) {
      ToolKind.stamp =>
        controller.stampImage != null ? '🖼️' : controller.stampEmoji,
      ToolKind.shape => shapes.shapeEmoji(controller.shapeKind),
      _ => toolEmoji(tool),
    };

    return _PickableButton(
      label: toolLabel(context, tool),
      accent: accent,
      selected: selected,
      size: size,
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Two motions on purpose: the scale is the *state* (this one is
          // picked, and stays bigger), the pulse is the *answer* (you just
          // picked it). `only: true` keeps the answer to the tool being
          // picked up — the one being put down stays quiet.
          Pulse(
            trigger: selected,
            only: true,
            peak: PixieMotion.pulsePeak,
            child: _SelectionScale(
              selected: selected,
              restOpacity: _PickableButton.toolRestOpacity,
              child: Text(emoji, style: TextStyle(fontSize: size * 0.46)),
            ),
          ),
          if (showColorBadge)
            Positioned(
              right: 6,
              bottom: 6,
              // The color is chosen at the *other* end of the screen — this
              // badge is where a child sees that their tap landed on the
              // tool they are about to draw with.
              child: Pulse(
                trigger: controller.color,
                peak: PixieMotion.pulsePeakLoud,
                child: AnimatedContainer(
                  duration: PixieMotion.select,
                  curve: PixieCurves.settle,
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: controller.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The selected state's own little motion: a hair bigger and at full
/// strength when picked, dimmed and back to normal size when not.
class _SelectionScale extends StatelessWidget {
  const _SelectionScale({
    required this.selected,
    required this.restOpacity,
    required this.child,
  });

  final bool selected;
  final double restOpacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? PixieMotion.selectedScale : 1.0,
      duration: PixieMotion.select,
      curve: PixieCurves.spring,
      child: Opacity(
        opacity: selected ? 1.0 : restOpacity,
        child: child,
      ),
    );
  }
}

/// Magic-mirror button: shows the active mode's motif (🦋/🌸/❄️), or a dimmed
/// butterfly when symmetry is off. Opens the symmetry picker sheet.
class _SymmetryButton extends StatelessWidget {
  const _SymmetryButton({
    required this.controller,
    required this.onTap,
    required this.size,
  });

  final CanvasController controller;
  final VoidCallback onTap;

  /// The rail's slot width. Hard-wired to 52 until v8.8, which put it half a
  /// tool out of step with the buttons beside it in the portrait bar and a
  /// whole one in the simple toolbar.
  final double size;

  @override
  Widget build(BuildContext context) {
    final active = controller.symmetryFolds > 1;
    return _PickableButton(
      label: context.l10n.symmetryTitle,
      accent: PixiePalette.periwinkle,
      selected: active,
      size: size,
      onTap: onTap,
      child: Center(
        child: _SelectionScale(
          selected: active,
          // Dimmer than a tool at rest: "off" is a real state of the mirror,
          // not just "some other tool is picked".
          restOpacity: 0.4,
          child: Text(
            active ? symmetry.symmetryEmoji(controller.symmetryFolds) : '🦋',
            style: TextStyle(fontSize: size * 0.46),
          ),
        ),
      ),
    );
  }
}

/// Single size button: a dot whose diameter tracks the current brush size.
/// Tapping opens the size sheet with the big slider and S/M/L presets.
class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.brushSize,
    required this.color,
    required this.onTap,
    required this.size,
  });

  final double brushSize;
  final Color color;
  final VoidCallback onTap;

  /// The rail's slot width — see [_SymmetryButton.size].
  final double size;

  @override
  Widget build(BuildContext context) {
    // Not just white: rosa is one of the sixteen, and a mixed colour can be
    // lighter still. The same rule the two palettes and the size sheet use.
    final light = needsBorder(color);
    // Map the canvas-unit size onto a readable 10–30 px preview dot.
    final t = (brushSize - kMinBrushSize) / (kMaxBrushSize - kMinBrushSize);
    final previewDiameter = 10.0 + t.clamp(0.0, 1.0) * 20.0;
    return Bouncy(
      onTap: onTap,
      playTick: false,
      semanticLabel: context.l10n.sizeTitle,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(1),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: PixieMotion.snap,
              curve: PixieCurves.settle,
              width: previewDiameter,
              height: previewDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: light ? PixieTokens.hairline() : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Icon(
                Icons.unfold_more_rounded,
                size: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.label,
    required this.size,
    this.filled = false,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  /// Spoken name — the button is an icon with no text of its own.
  final String label;
  final bool filled;

  /// The rail's slot width — see [_SymmetryButton.size].
  final double size;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: enabled ? onTap : null,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: PixieMotion.snap,
        curve: PixieCurves.settle,
        width: size,
        height: size,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: filled && enabled ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: PixieTokens.softShadow(PixiePalette.grape,
              strength: filled && enabled ? 1.0 : 0.0),
        ),
        child: Icon(
          icon,
          size: size * 0.54,
          color: enabled
              ? PixiePalette.ink.withValues(alpha: 0.7)
              : PixiePalette.ink.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
