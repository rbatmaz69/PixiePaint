import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'settings.dart';

/// Gentle background-music loops, off by default (parent opt-in in settings,
/// kid-facing toggle on the home screen). Same failure philosophy as Sfx:
/// audio must never crash the app, so every call is try/catch-silent.
///
/// Owns its own lifecycle observer: playback pauses when the app goes to the
/// background and resumes with it, independent of any screen.
class Music with WidgetsBindingObserver {
  Music._();
  static final Music instance = Music._();

  /// Seamless WAV loops — compressed formats gap at the loop point.
  static const List<String> tracks = [
    'sounds/music/lullaby.wav',
    'sounds/music/sunshine.wav',
  ];

  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  Future<void> init() async {
    try {
      WidgetsBinding.instance.addObserver(this);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.25);
      if (Settings.instance.musicOn) await _start();
    } catch (_) {}
  }

  bool get playing => _playing;

  /// Starts the current track and advances the cursor, so every fresh start
  /// brings the next song — a little variety without a track picker.
  Future<void> _start() async {
    final index =
        Settings.instance.musicTrack.clamp(0, tracks.length - 1).toInt();
    try {
      await _player.play(AssetSource(tracks[index]));
      _playing = true;
      Settings.instance.update(musicTrack: (index + 1) % tracks.length);
    } catch (_) {}
  }

  Future<void> setOn(bool on) async {
    try {
      if (on) {
        await _start();
      } else {
        _playing = false;
        await _player.stop();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_playing) return;
    try {
      if (state == AppLifecycleState.resumed) {
        _player.resume();
      } else if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        _player.pause();
      }
    } catch (_) {}
  }
}
