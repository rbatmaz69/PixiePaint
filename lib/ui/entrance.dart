/// The app's one entrance animation: content fades in, rises a little and
/// settles from a hair too small, staggered by slot so a screen assembles
/// itself instead of appearing all at once.
///
/// Three screens used to carry their own copy of these fifteen lines with
/// slightly different numbers. This is that code, once, with two ways in:
///
/// * [EntranceMixin] on a screen's `State` — `entrance(slot, child)`. Adds
///   nothing to the widget tree, so a screen that already has a State keeps
///   its shape.
/// * [EntranceGroup] around a subtree plus [Entrance] inside it — for grids
///   built by stateless widgets that have no controller to reach for.
///
/// Both share [buildEntrance] below, so the movement is identical.
library;

import 'package:flutter/material.dart';

import 'motion.dart';

/// Delay per slot, as a fraction of the run. Clamped at 0.5 so a long grid
/// still finishes inside the controller's run instead of piling up at the
/// end.
const double _slotStep = 0.05;

/// How long a full cascade takes, first slot to last.
const Duration kEntranceDuration = Duration(milliseconds: 900);

/// Fade + rise + a touch of scale on [controller], offset by [slot].
///
/// With "reduce motion" on the content still arrives — it just fades in
/// where it belongs instead of rising into place.
Widget buildEntrance(
  BuildContext context,
  Animation<double> controller,
  int slot,
  Widget child,
) {
  final start = (_slotStep * slot).clamp(0.0, 0.5);
  final anim = CurvedAnimation(
    parent: controller,
    curve: Interval(
      start,
      (start + 0.5).clamp(0.0, 1.0),
      curve: Curves.easeOutCubic,
    ),
  );
  if (reducedMotion(context)) {
    return FadeTransition(opacity: anim, child: child);
  }
  return FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(anim),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
        child: child,
      ),
    ),
  );
}

/// Gives a screen's [State] one entrance controller and the [entrance]
/// helper. Mix in after [SingleTickerProviderStateMixin], then wrap each
/// piece: `entrance(0, header)`.
mixin EntranceMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  /// Created on first use, so the animation starts when content actually
  /// appears rather than while a picker is still loading from disk.
  ///
  /// The nullable backing field is what makes that safe: leaving a screen
  /// before its load finished means [entrance] was never called, and a plain
  /// `late final` would then *create* the controller inside dispose(), where
  /// the element tree is already deactivated — an outright crash. On a device
  /// with a big gallery and slow storage that is a very short window to hit.
  AnimationController? _entranceOrNull;

  AnimationController get _entrance => _entranceOrNull ??= AnimationController(
        vsync: this,
        duration: kEntranceDuration,
      )..forward();

  /// One piece of the cascade; [slot] is its position, 0 arrives first.
  Widget entrance(int slot, Widget child) =>
      buildEntrance(context, _entrance, slot, child);

  @override
  void dispose() {
    _entranceOrNull?.dispose();
    super.dispose();
  }
}

/// Hands one entrance controller to every [Entrance] below it. For subtrees
/// built by stateless widgets; a screen with its own State should use
/// [EntranceMixin] instead.
class EntranceGroup extends StatefulWidget {
  const EntranceGroup({super.key, required this.child});

  final Widget child;

  @override
  State<EntranceGroup> createState() => _EntranceGroupState();
}

class _EntranceGroupState extends State<EntranceGroup>
    with SingleTickerProviderStateMixin, EntranceMixin {
  @override
  Widget build(BuildContext context) =>
      _EntranceScope(controller: _entrance, child: widget.child);
}

class _EntranceScope extends InheritedWidget {
  const _EntranceScope({required this.controller, required super.child});

  final Animation<double> controller;

  @override
  bool updateShouldNotify(_EntranceScope old) => old.controller != controller;
}

/// One piece of an [EntranceGroup]'s cascade; [slot] is its position, 0
/// arrives first. Without a group above it this is a plain pass-through, so
/// a widget stays usable on its own and in tests.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.slot, required this.child});

  final int slot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_EntranceScope>();
    if (scope == null) return child;
    return buildEntrance(context, scope.controller, slot, child);
  }
}
