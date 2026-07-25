import 'package:flutter/material.dart';

/// Whether the device asks for less movement.
///
/// Android's "Remove animations" and iOS's "Reduce Motion" both arrive as
/// [MediaQueryData.disableAnimations]. This app is built out of motion —
/// drifting blobs, springy buttons, confetti — and until v8.3 nothing here
/// ever asked. For a child with vestibular trouble, or one who simply gets
/// overwhelmed, that setting is the difference between using the app and
/// putting it down.
///
/// What it must not do is take the *reward* away: the sticker still
/// unlocks, the party still happens, it just fades in instead of flying.
bool reducedMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// [full] normally, [reduced] (or nothing at all) when motion is off.
Duration motionDuration(BuildContext context, Duration full,
        {Duration reduced = Duration.zero}) =>
    reducedMotion(context) ? reduced : full;

/// How long things take. Colors, radii and shadows have been tokens for a
/// while; time was not, and it showed — the *same* interaction ran at seven
/// different speeds. Picking a shape took 150 ms, picking a tool 220 ms,
/// picking a color 260 ms, and the color chip's own border followed 80 ms
/// behind its scale because the two `AnimatedContainer`s on one widget had
/// been given different numbers.
///
/// These are named after what they are *for*, not how long they are, so a
/// call site can only ask the question it actually has: "is this a
/// selection?" rather than "was it 220 or 240?".
///
/// **What this ladder does not govern:** choreographed effects, whose
/// timings answer to each other rather than to a rung — the confetti
/// scales, `fill_burst`, `stamp_burst`, the pause curtain, the reward
/// reveal's flight and landing, `LoadingPixie`'s hop, the slideshow's Ken
/// Burns, and everything in `replay_controller.dart` (that is playback
/// timing, not design). Pulling those onto the ladder is how a ladder ends
/// up with twenty rungs and stops meaning anything.
abstract final class PixieMotion {
  /// Tracks a finger: the press-down squash, and any value that follows a
  /// drag (the brush-size preview under the slider). Fast enough to read as
  /// contact rather than as animation — anything slower here feels like lag,
  /// not like polish.
  static const Duration press = Duration(milliseconds: 90);

  /// The small stuff that just has to keep up: a badge dot recoloring, a
  /// preview circle tracking a slider.
  static const Duration snap = Duration(milliseconds: 180);

  /// **The** selection time: every picker tile, chip, pill and toolbar
  /// button that can be chosen. Also every piece of chrome that fades or
  /// slides itself in and out. If you are unsure, it is this one.
  static const Duration select = Duration(milliseconds: 240);

  /// Something arrives on top: dialog, sheet, curtain, overlay.
  static const Duration enter = Duration(milliseconds: 340);

  /// The elastic ride back after a press.
  static const Duration spring = Duration(milliseconds: 450);

  /// An emoji makes an entrance.
  static const Duration pop = Duration(milliseconds: 550);

  /// A whole screen assembles itself — see `kEntranceDuration`.
  static const Duration stage = Duration(milliseconds: 900);

  /// An emoji waits this long before making its entrance, so the box it
  /// sits in has arrived first. Three places had 80, 100 and 120 ms.
  static const Duration emojiDelay = Duration(milliseconds: 120);

  // ---- How long something *stays*. Not a speed — never shortened by
  // reduce motion, because a hint a child cannot finish reading is worse
  // than one that moves.
  static const Duration dwell = Duration(milliseconds: 1500);
  static const Duration dwellLong = Duration(seconds: 6);

  /// A chosen tile sits a hair proud of its neighbours.
  static const double selectedScale = 1.18;

  /// How far a press squashes.
  static const double pressedScale = 0.9;

  /// The default [Pulse] peak, and the louder one for the color badge —
  /// that badge is the only feedback that a color picked at the far end of
  /// the screen landed on the tool, so it is allowed to shout.
  static const double pulsePeak = 1.15;
  static const double pulsePeakLoud = 1.35;
}

/// The five curves this app uses. Named by role for the same reason as
/// [PixieMotion] — and because two of them carry a trap worth naming.
abstract final class PixieCurves {
  /// Arriving somewhere: decelerating, no overshoot.
  static const Curve enter = Curves.easeOutCubic;

  /// Playful overshoot for selections and entrances.
  ///
  /// Careful: this curve leaves the 0..1 range at **both** ends, so
  /// anything it drives must stay valid outside it. A `boxShadow` tweened
  /// against `null` has its blur pulled below zero on the undershoot, and
  /// `dart:ui` asserts on that — keep the shadow present and move only its
  /// alpha (see `_selectionShadow` in `tool_bar.dart`).
  static const Curve spring = Curves.easeOutBack;

  /// Coming to rest without drama.
  static const Curve settle = Curves.easeOut;

  /// A real bounce, with wobble. Expensive-looking; use sparingly.
  static const Curve bounce = Curves.elasticOut;

  /// Leaving. Only ever a reverse curve.
  static const Curve exit = Curves.easeIn;
}
