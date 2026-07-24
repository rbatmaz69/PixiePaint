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

  /// Artwork shared.
  void tada() {
    try {
      if (_audible) _tada?.play(AssetSource('sounds/tada.wav'));
      if (_tactile) HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
