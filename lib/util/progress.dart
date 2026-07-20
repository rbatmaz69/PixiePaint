import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/reward.dart';
import '../models/tool.dart';
import 'settings.dart';

/// Kid progress towards sticker rewards, persisted as progress.json in the
/// documents dir (kept separate from the parent-facing settings.json).
class Progress extends ChangeNotifier {
  Progress._();
  static final Progress instance = Progress._();

  /// Artworks that were painted on and saved at least once. Capped well
  /// above the highest painting target so the file stays tiny.
  final Set<String> completedArtworkIds = {};
  static const int _maxTrackedArtworks = 50;

  /// ToolKind names that actually painted something (not mere selection).
  final Set<String> toolsUsed = {};

  /// Rewards whose unlock party has already been shown.
  final Set<String> celebratedEmojis = {};

  File? _file;

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/progress.json');
      if (await _file!.exists()) {
        final json = jsonDecode(await _file!.readAsString());
        completedArtworkIds.addAll(
            ((json['completedArtworkIds'] as List?) ?? []).whereType<String>());
        toolsUsed
            .addAll(((json['toolsUsed'] as List?) ?? []).whereType<String>());
        celebratedEmojis.addAll(
            ((json['celebratedEmojis'] as List?) ?? []).whereType<String>());
      }
    } catch (_) {
      // starting from zero is fine
    }
  }

  ProgressSnapshot snapshot() => ProgressSnapshot(
        paintings: completedArtworkIds.length,
        toolsUsed: toolsUsed.length,
        shares: Settings.instance.shareCount,
      );

  void registerArtworkCompleted(String id) {
    if (completedArtworkIds.contains(id) ||
        completedArtworkIds.length >= _maxTrackedArtworks) {
      return;
    }
    completedArtworkIds.add(id);
    _persist();
    notifyListeners();
  }

  void registerToolUsed(ToolKind kind) {
    // Only persist when the set actually grows — this is called on every
    // stroke commit.
    if (!toolsUsed.add(kind.name)) return;
    _persist();
    notifyListeners();
  }

  /// Newly unlocked rewards that still need their party; marks them
  /// celebrated so each one fires exactly once.
  List<StickerReward> takeUncelebrated() {
    final fresh = uncelebrated(snapshot(), celebratedEmojis);
    if (fresh.isEmpty) return fresh;
    celebratedEmojis.addAll(fresh.map((r) => r.emoji));
    _persist();
    return fresh;
  }

  bool isRewardUnlocked(StickerReward reward) =>
      isUnlocked(reward, snapshot());

  Future<void> _persist() async {
    try {
      await _file?.writeAsString(jsonEncode({
        'completedArtworkIds': completedArtworkIds.toList(),
        'toolsUsed': toolsUsed.toList(),
        'celebratedEmojis': celebratedEmojis.toList(),
      }));
    } catch (_) {}
  }
}
