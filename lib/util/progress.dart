import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/reward.dart';
import '../models/tool.dart';
import 'json_store.dart';
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

  /// Tracing templates finished at least once (letter/number/shape ids).
  final Set<String> completedTraceIds = {};

  /// Color-by-number pages fully solved at least once.
  final Set<String> completedCbnIds = {};

  /// Daily prompts marked as done (total) and the last day it happened,
  /// as a `yyyy-MM-dd` key so a day counts exactly once.
  int tasksDone = 0;
  String lastTaskDay = '';

  /// Rewards whose unlock party has already been shown.
  final Set<String> celebratedEmojis = {};

  JsonStore? _store;

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await loadFrom(JsonStore(File('${dir.path}/progress.json')));
    } catch (_) {
      // starting from zero is fine
    }
  }

  /// Seam for tests: load from any store (a temp file) instead of the real
  /// documents dir.
  Future<void> loadFrom(JsonStore store) async {
    _store = store;
    final json = await store.read();
    if (json == null) return;
    completedArtworkIds.addAll(
        ((json['completedArtworkIds'] as List?) ?? []).whereType<String>());
    toolsUsed.addAll(((json['toolsUsed'] as List?) ?? []).whereType<String>());
    completedTraceIds.addAll(
        ((json['completedTraceIds'] as List?) ?? []).whereType<String>());
    completedCbnIds.addAll(
        ((json['completedCbnIds'] as List?) ?? []).whereType<String>());
    tasksDone = json['tasksDone'] as int? ?? 0;
    lastTaskDay = json['lastTaskDay'] as String? ?? '';
    celebratedEmojis.addAll(
        ((json['celebratedEmojis'] as List?) ?? []).whereType<String>());
  }

  /// Test seam: forget everything loaded so far.
  @visibleForTesting
  void resetForTest() {
    completedArtworkIds.clear();
    toolsUsed.clear();
    completedTraceIds.clear();
    completedCbnIds.clear();
    celebratedEmojis.clear();
    tasksDone = 0;
    lastTaskDay = '';
    _store = null;
  }

  ProgressSnapshot snapshot() => ProgressSnapshot(
        paintings: completedArtworkIds.length,
        toolsUsed: toolsUsed.length,
        shares: Settings.instance.shareCount,
        tracesDone: completedTraceIds.length,
        cbnDone: completedCbnIds.length,
        tasksDone: tasksDone,
      );

  bool isTaskDoneOn(String dayKey) => lastTaskDay == dayKey;

  /// Counts today's prompt as done — at most once per calendar day.
  void registerDailyTaskDone(String dayKey) {
    if (lastTaskDay == dayKey) return;
    lastTaskDay = dayKey;
    tasksDone++;
    _persist();
    notifyListeners();
  }

  void registerArtworkCompleted(String id) {
    if (completedArtworkIds.contains(id) ||
        completedArtworkIds.length >= _maxTrackedArtworks) {
      return;
    }
    completedArtworkIds.add(id);
    _persist();
    notifyListeners();
  }

  void registerTraceCompleted(String traceId) {
    if (!completedTraceIds.add(traceId)) return;
    _persist();
    notifyListeners();
  }

  void registerCbnCompleted(String pageId) {
    if (!completedCbnIds.add(pageId)) return;
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
    notifyListeners();
    return fresh;
  }

  bool isRewardUnlocked(StickerReward reward) =>
      isUnlocked(reward, snapshot());

  /// Queued and atomic — see [JsonStore]. Callers stay fire-and-forget.
  Future<void> _persist() async {
    await _store?.write({
      'completedArtworkIds': completedArtworkIds.toList(),
      'toolsUsed': toolsUsed.toList(),
      'completedTraceIds': completedTraceIds.toList(),
      'completedCbnIds': completedCbnIds.toList(),
      'tasksDone': tasksDone,
      'lastTaskDay': lastTaskDay,
      'celebratedEmojis': celebratedEmojis.toList(),
    });
  }

  /// Waits until every queued write reached the disk.
  Future<void> flush() async => _store?.flush();
}
