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
const Duration kEntranceDuration = PixieMotion.stage;

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
      curve: PixieCurves.enter,
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

  /// Like [entrance], but a tile built after the cascade is over still
  /// arrives — for the item builders of long, lazy grids. See [Reveal].
  Widget reveal(int slot, Widget child) =>
      Reveal(slot: slot, cascade: _entrance, child: child);

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

/// Like [Entrance], but it also arrives for tiles that are *scrolled* into
/// view rather than being there from the start.
///
/// The cascade staggers one screenful and is then over. By the time the
/// fortieth picture in a gallery is built, the controller finished long ago,
/// so that tile is handed an opacity of 1 and simply blinks into existence —
/// the bottom of a long grid feels dead in a way the top does not.
///
/// Lazy building is the visibility detector, which is why this needs no
/// package and no measuring: `GridView.builder` only constructs a tile when
/// it is about to be seen, so a tile constructed *after* the cascade
/// finished is by definition one the reader just scrolled to. It then runs
/// the same movement on its own controller, at slot 0 — not a second,
/// similar animation, but literally [buildEntrance] again, so the two can
/// never drift apart.
/// Both ways into the cascade work, matching [Entrance] and [EntranceMixin]:
/// pass [cascade] from a screen that has the mixin, or leave it null inside
/// an [EntranceGroup].
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.slot,
    required this.child,
    this.cascade,
  });

  final int slot;
  final Widget child;

  /// The screen's shared entrance controller, for [EntranceMixin] users.
  /// Null looks for an [EntranceGroup] above instead.
  final Animation<double>? cascade;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  /// Nullable backing field, not `late final`: a tile that is scrolled past
  /// and disposed before it ever built would otherwise create its
  /// controller inside `dispose()`. That is README rule 4, and a long
  /// gallery flicked hard is exactly where it would happen.
  AnimationController? _ownOrNull;
  Animation<double>? _cascade;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    _cascade = widget.cascade ??
        context
            .dependOnInheritedWidgetOfExactType<_EntranceScope>()
            ?.controller;
    final c = _cascade;
    // Nothing above: stay a plain pass-through, exactly like [Entrance].
    if (c == null || !c.isCompleted) return;
    _ownOrNull = AnimationController(vsync: this, duration: kEntranceDuration)
      ..forward();
  }

  @override
  void dispose() {
    _ownOrNull?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final own = _ownOrNull;
    if (own != null) return buildEntrance(context, own, 0, widget.child);
    final c = _cascade;
    if (c == null) return widget.child;
    return buildEntrance(context, c, widget.slot, widget.child);
  }
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
