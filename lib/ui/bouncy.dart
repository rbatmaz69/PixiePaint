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
    this.pressedScale = 0.9,
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
      duration: _pressed || calm
          ? const Duration(milliseconds: 90)
          : const Duration(milliseconds: 450),
      curve: _pressed || calm ? Curves.easeOut : Curves.elasticOut,
      child: widget.child,
    );
    if (widget.minSize > 0) {
      child = ConstrainedBox(
        constraints: BoxConstraints(
            minWidth: widget.minSize, minHeight: widget.minSize),
        child: Center(child: child),
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
