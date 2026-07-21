import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:path_provider/path_provider.dart';

import 'color_utils.dart';

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

  /// Successful shares so far — drives the one-time review prompt.
  int shareCount = 0;
  bool reviewRequested = false;

  /// Most-recent-first ARGB values picked via the big color sheet or the
  /// eyedropper — shown as a quick-access row in the picker.
  List<int> recentColors = [];

  File? _file;

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/settings.json');
      if (await _file!.exists()) {
        final json = jsonDecode(await _file!.readAsString());
        stylusOnly = json['stylusOnly'] as bool? ?? false;
        deleteNeedsGate = json['deleteNeedsGate'] as bool? ?? false;
        soundsOn = json['soundsOn'] as bool? ?? true;
        musicOn = json['musicOn'] as bool? ?? false;
        musicTrack = json['musicTrack'] as int? ?? 0;
        leftHanded = json['leftHanded'] as bool? ?? false;
        shareCount = json['shareCount'] as int? ?? 0;
        reviewRequested = json['reviewRequested'] as bool? ?? false;
        recentColors = (json['recentColors'] as List?)
                ?.whereType<int>()
                .toList() ??
            [];
      }
    } catch (_) {
      // defaults are fine
    }
  }

  Future<void> update(
      {bool? stylusOnly,
      bool? deleteNeedsGate,
      bool? soundsOn,
      bool? musicOn,
      int? musicTrack,
      bool? leftHanded}) async {
    if (stylusOnly != null) this.stylusOnly = stylusOnly;
    if (deleteNeedsGate != null) this.deleteNeedsGate = deleteNeedsGate;
    if (soundsOn != null) this.soundsOn = soundsOn;
    if (musicOn != null) this.musicOn = musicOn;
    if (musicTrack != null) this.musicTrack = musicTrack;
    if (leftHanded != null) this.leftHanded = leftHanded;
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
    await _persist();
  }

  Future<void> markReviewRequested() async {
    reviewRequested = true;
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _file?.writeAsString(jsonEncode({
        'stylusOnly': stylusOnly,
        'deleteNeedsGate': deleteNeedsGate,
        'soundsOn': soundsOn,
        'musicOn': musicOn,
        'musicTrack': musicTrack,
        'leftHanded': leftHanded,
        'shareCount': shareCount,
        'reviewRequested': reviewRequested,
        'recentColors': recentColors,
      }));
    } catch (_) {}
  }
}
