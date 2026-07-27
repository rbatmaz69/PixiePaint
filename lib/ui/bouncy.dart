import 'package:flutter/material.dart';

import '../util/sfx.dart';
import 'motion.dart';

/// The app-wide press effect: squash to [pressedScale] on touch-down, spring
/// back with an elastic bounce on release. Uses only `Transform.scale`
/// (via [AnimatedScale]) — never a layout change.
class Bouncy extends StatefulWidget {
  const Bouncy({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.playTick = true,
    this.minSize = 48.0,
    this.pressedScale = PixieMotion.pressedScale,
    this.semanticLabel,
    this.semanticSelected,
  });

  /// Announced alongside [semanticLabel] for controls that are part of a
  /// choice — which brush is active, which color is picked. Without it a
  /// screen reader can read the whole toolbar without revealing which of
  /// the buttons is the current one.
  final bool? semanticSelected;

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// What a screen reader announces. Almost every control in the app is a
  /// [Bouncy], and a raw [GestureDetector] is invisible to TalkBack and
  /// VoiceOver — so this is where accessibility enters the app. Leave it
  /// null only where the child already carries readable text.
  final String? semanticLabel;

  /// Set to false where the tap handler already plays a sound (e.g. the
  /// canvas controller ticks on tool/color selection).
  final bool playTick;

  /// Minimum hit area (kids-app rule: ≥48 px). Set to 0 to opt out.
  final double minSize;

  final double pressedScale;

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    // With "reduce motion" on, the press still answers — it just stops
    // springing. Almost every control in this app is a Bouncy, so this one
    // branch is most of what that setting means here.
    final calm = reducedMotion(context);
    Widget child = AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1.0,
      duration: _pressed || calm ? PixieMotion.press : PixieMotion.spring,
      curve: _pressed || calm ? PixieCurves.settle : PixieCurves.bounce,
      child: widget.child,
    );
    if (widget.minSize > 0) {
      child = ConstrainedBox(
        constraints: BoxConstraints(
            minWidth: widget.minSize, minHeight: widget.minSize),
        // The factors are what keep this from being a layout change rather
        // than a hit-area one. A plain Center fills whatever room it is
        // offered, and a Bouncy sits inside almost every control in the app
        // — in a Wrap that meant each card claimed the entire row, so the
        // home screen quietly rendered as one column on every phone while
        // the code above it was busy computing two. With the factors the
        // box hugs its child, and the minimum still lifts a small one to
        // 48 because the incoming constraint says so.
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      );
    }
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      selected: widget.semanticSelected,
      // The gesture below is the real handler; announcing it here is what
      // makes the control reachable by a screen reader at all.
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.playTick) Sfx.instance.tick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: child,
      ),
    );
  }
}
