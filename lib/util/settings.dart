import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:path_provider/path_provider.dart';

import 'color_utils.dart';
import 'json_store.dart';

/// What a parent can pick for the painting-break reminder. 0 = off, which
/// stays the default: the app should not start policing screen time unless
/// a parent asks it to.
const List<int> kPauseChoices = [0, 20, 30, 45];

/// App settings, persisted as a small JSON file in the documents dir.
class Settings extends ChangeNotifier {
  Settings._();
  static final Settings instance = Settings._();

  bool stylusOnly = false;
  bool deleteNeedsGate = false;
  bool soundsOn = true;
  bool musicOn = false;

  /// Mirrors the canvas layout: tool rail on the right (landscape) and the
  /// floating buttons swapped, so a left drawing hand never crosses them.
  bool leftHanded = false;

  /// Which background-music loop plays next (cycled by Music on each start).
  int musicTrack = 0;

  /// Whether the one-time welcome has been shown. Everything else here is a
  /// preference; this is a flag the app sets itself.
  bool welcomeSeen = false;

  /// Whether the one-time "turn me sideways" nudge has been shown on the
  /// canvas. Same kind of flag as [welcomeSeen] — the app writing about
  /// itself, not a parent choosing something.
  bool rotateHintSeen = false;

  /// Minutes of painting before the app suggests a break, or 0 for never.
  /// Only the values in [kPauseChoices] are offered.
  int pauseAfterMinutes = 0;

  /// Successful shares so far — drives the one-time review prompt.
  int shareCount = 0;
  bool reviewRequested = false;

  /// Most-recent-first ARGB values picked via the big color sheet or the
  /// eyedropper — shown as a quick-access row in the picker.
  List<int> recentColors = [];

  JsonStore? _store;

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await loadFrom(JsonStore(File('${dir.path}/settings.json')));
    } catch (_) {
      // defaults are fine
    }
  }

  /// Seam for tests: load from any store instead of the documents dir.
  Future<void> loadFrom(JsonStore store) async {
    _store = store;
    final json = await store.read();
    if (json == null) return;
    stylusOnly = json['stylusOnly'] as bool? ?? false;
    deleteNeedsGate = json['deleteNeedsGate'] as bool? ?? false;
    soundsOn = json['soundsOn'] as bool? ?? true;
    musicOn = json['musicOn'] as bool? ?? false;
    musicTrack = json['musicTrack'] as int? ?? 0;
    pauseAfterMinutes = json['pauseAfterMinutes'] as int? ?? 0;
    welcomeSeen = json['welcomeSeen'] as bool? ?? false;
    rotateHintSeen = json['rotateHintSeen'] as bool? ?? false;
    leftHanded = json['leftHanded'] as bool? ?? false;
    shareCount = json['shareCount'] as int? ?? 0;
    reviewRequested = json['reviewRequested'] as bool? ?? false;
    recentColors =
        (json['recentColors'] as List?)?.whereType<int>().toList() ?? [];
  }

  Future<void> update(
      {bool? stylusOnly,
      bool? deleteNeedsGate,
      bool? soundsOn,
      bool? musicOn,
      int? musicTrack,
      bool? leftHanded,
      int? pauseAfterMinutes}) async {
    if (stylusOnly != null) this.stylusOnly = stylusOnly;
    if (deleteNeedsGate != null) this.deleteNeedsGate = deleteNeedsGate;
    if (soundsOn != null) this.soundsOn = soundsOn;
    if (musicOn != null) this.musicOn = musicOn;
    if (musicTrack != null) this.musicTrack = musicTrack;
    if (leftHanded != null) this.leftHanded = leftHanded;
    if (pauseAfterMinutes != null) {
      this.pauseAfterMinutes = pauseAfterMinutes;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> registerRecentColor(Color c) async {
    recentColors = pushRecentArgb(recentColors, c.toARGB32());
    notifyListeners();
    await _persist();
  }

  Future<void> registerShare() async {
    shareCount++;
    notifyListeners();
    await _persist();
  }

  Future<void> markReviewRequested() async {
    reviewRequested = true;
    await _persist();
  }

  /// Queued and atomic — see [JsonStore].
  Future<void> _persist() async {
    await _store?.write({
      'stylusOnly': stylusOnly,
      'deleteNeedsGate': deleteNeedsGate,
      'soundsOn': soundsOn,
      'musicOn': musicOn,
      'musicTrack': musicTrack,
      'leftHanded': leftHanded,
      'pauseAfterMinutes': pauseAfterMinutes,
      'welcomeSeen': welcomeSeen,
      'rotateHintSeen': rotateHintSeen,
      'shareCount': shareCount,
      'reviewRequested': reviewRequested,
      'recentColors': recentColors,
    });
  }

  /// Remembers that the welcome has run. Its own method because it is the
  /// app writing about itself, not a parent changing a setting.
  Future<void> markWelcomeSeen() async {
    if (welcomeSeen) return;
    welcomeSeen = true;
    notifyListeners();
    await _persist();
  }

  /// Remembers that the rotate nudge has run. Written the moment it appears,
  /// not when it is dismissed: a hint the app was killed underneath is still
  /// a hint that was shown.
  Future<void> markRotateHintSeen() async {
    if (rotateHintSeen) return;
    rotateHintSeen = true;
    notifyListeners();
    await _persist();
  }

  /// Waits until every queued write reached the disk.
  Future<void> flush() async => _store?.flush();

  /// Back to a fresh install. Matches the seam [Progress] and [ProfileStore]
  /// already have — without it this singleton carries one test's choices
  /// into the next.
  @visibleForTesting
  void resetForTest() {
    stylusOnly = false;
    deleteNeedsGate = false;
    soundsOn = true;
    musicOn = false;
    musicTrack = 0;
    leftHanded = false;
    pauseAfterMinutes = 0;
    welcomeSeen = false;
    rotateHintSeen = false;
    shareCount = 0;
    reviewRequested = false;
    recentColors = [];
    _store = null;
  }
}
