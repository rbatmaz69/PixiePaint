import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'settings.dart';

/// UI sound effects with paired haptics. Every call is a cheap no-op when
/// sounds are disabled, and playback failures are swallowed — audio must
/// never crash the app.
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  AudioPool? _pop;
  AudioPool? _tick;
  AudioPool? _draw;

  /// Created in [init], never in a field initializer: constructing an
  /// `AudioPlayer` reaches for the platform channel straight away, and
  /// where there is none — every unit test — that rejects as an unhandled
  /// async error. Anything that so much as ticks would then fail a test it
  /// has nothing to do with.
  AudioPlayer? _tada;

  Future<void> init() async {
    try {
      _tada = AudioPlayer();
      _pop = await AudioPool.createFromAsset(
          path: 'sounds/pop.wav', maxPlayers: 2);
      _tick = await AudioPool.createFromAsset(
          path: 'sounds/tick.wav', maxPlayers: 2);
      // Three players: strokes can start on top of each other with two
      // fingers, and a fourth would only ever be the sound overlapping
      // itself into a hiss.
      _draw = await AudioPool.createFromAsset(
          path: 'sounds/draw.wav', maxPlayers: 3);
    } catch (_) {
      // No audio backend (e.g. tests) — stay silent.
    }
  }

  bool get _audible => Settings.instance.soundsOn;

  /// Sound and touch are asked separately since v8.3. They used to share one
  /// switch, so a tablet muted in a waiting room also stopped answering a
  /// tap in the one way that still worked there.
  bool get _tactile => Settings.instance.hapticsOn;

  /// Fill landed / stamp placed.
  void pop() {
    try {
      if (_audible) _pop?.start();
      if (_tactile) HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Tool, color or size selected.
  void tick() {
    try {
      if (_audible) _tick?.start(volume: 0.6);
      if (_tactile) HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// A stroke has begun.
  ///
  /// One short sound at the start, not a tone held for the length of the
  /// stroke. A held tone would need a looping player of its own, and on
  /// Android it stutters audibly every time it is restarted — a lot of
  /// machinery to buy something worse.
  ///
  /// No haptic: the drawing hand is already touching the screen, and a
  /// buzz under a moving finger reads as the app snagging.
  void draw() {
    try {
      if (_audible) _draw?.start(volume: 0.5);
    } catch (_) {}
  }

  /// Artwork shared.
  void tada() {
    try {
      if (_audible) _tada?.play(AssetSource('sounds/tada.wav'));
      if (_tactile) HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
