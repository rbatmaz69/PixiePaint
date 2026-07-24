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
