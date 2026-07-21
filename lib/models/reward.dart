import 'dart:math';

/// What a sticker reward counts: finished paintings, distinct tools used,
/// successful shares, finished tracing templates, or solved
/// color-by-number pages.
enum RewardGoalKind { paintings, tools, shares, tracing, cbn }

/// An unlockable stamp motif with a simple, kid-explainable goal.
class StickerReward {
  final String emoji;
  final RewardGoalKind kind;
  final int target;

  const StickerReward(this.emoji, this.kind, this.target);
}

/// Unlockable stickers, easiest first. Emojis must not overlap with
/// [kStamps] and must render in color on both platforms (same caveat as
/// kStamps — swap out here if a device shows one monochrome).
const List<StickerReward> kRewards = [
  StickerReward('🦖', RewardGoalKind.paintings, 3),
  StickerReward('🚀', RewardGoalKind.paintings, 5),
  StickerReward('🧜‍♀️', RewardGoalKind.paintings, 8),
  StickerReward('🐉', RewardGoalKind.paintings, 12),
  StickerReward('🏰', RewardGoalKind.paintings, 16),
  StickerReward('🎠', RewardGoalKind.paintings, 20),
  StickerReward('🪄', RewardGoalKind.tools, 5),
  StickerReward('🛸', RewardGoalKind.tools, 9),
  StickerReward('💎', RewardGoalKind.shares, 1),
];

/// Immutable view of the counters the rewards are measured against.
class ProgressSnapshot {
  final int paintings;
  final int toolsUsed;
  final int shares;
  final int tracesDone;
  final int cbnDone;

  const ProgressSnapshot({
    required this.paintings,
    required this.toolsUsed,
    required this.shares,
    this.tracesDone = 0,
    this.cbnDone = 0,
  });
}

int progressFor(StickerReward reward, ProgressSnapshot s) =>
    switch (reward.kind) {
      RewardGoalKind.paintings => s.paintings,
      RewardGoalKind.tools => s.toolsUsed,
      RewardGoalKind.shares => s.shares,
      RewardGoalKind.tracing => s.tracesDone,
      RewardGoalKind.cbn => s.cbnDone,
    };

bool isUnlocked(StickerReward reward, ProgressSnapshot s) =>
    progressFor(reward, s) >= reward.target;

List<StickerReward> unlockedRewards(ProgressSnapshot s) =>
    kRewards.where((r) => isUnlocked(r, s)).toList();

int remainingFor(StickerReward reward, ProgressSnapshot s) =>
    max(0, reward.target - progressFor(reward, s));

/// Unlocked rewards whose celebration hasn't been shown yet.
List<StickerReward> uncelebrated(
        ProgressSnapshot s, Set<String> celebratedEmojis) =>
    unlockedRewards(s)
        .where((r) => !celebratedEmojis.contains(r.emoji))
        .toList();
