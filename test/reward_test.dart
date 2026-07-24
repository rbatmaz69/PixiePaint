import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/models/reward.dart';
import 'package:pixiepaint/models/stamp.dart';

ProgressSnapshot snap({int paintings = 0, int tools = 0, int shares = 0}) =>
    ProgressSnapshot(paintings: paintings, toolsUsed: tools, shares: shares);

void main() {
  const dino = StickerReward('🦖', RewardGoalKind.paintings, 3);
  const wand = StickerReward('🪄', RewardGoalKind.tools, 5);
  const gem = StickerReward('💎', RewardGoalKind.shares, 1);

  group('isUnlocked', () {
    test('below, at and above the threshold', () {
      expect(isUnlocked(dino, snap(paintings: 2)), isFalse);
      expect(isUnlocked(dino, snap(paintings: 3)), isTrue);
      expect(isUnlocked(dino, snap(paintings: 10)), isTrue);
    });

    test('each goal kind reads its own counter', () {
      expect(isUnlocked(wand, snap(paintings: 99)), isFalse);
      expect(isUnlocked(wand, snap(tools: 5)), isTrue);
      expect(isUnlocked(gem, snap(shares: 1)), isTrue);
      expect(isUnlocked(gem, snap(tools: 99)), isFalse);
    });
  });

  group('remainingFor', () {
    test('counts down and clamps at zero', () {
      expect(remainingFor(dino, snap()), 3);
      expect(remainingFor(dino, snap(paintings: 2)), 1);
      expect(remainingFor(dino, snap(paintings: 7)), 0);
    });
  });

  group('unlockedRewards', () {
    test('is monotonic: more progress never locks a reward', () {
      final some = unlockedRewards(snap(paintings: 5, tools: 5));
      final more = unlockedRewards(snap(paintings: 12, tools: 9, shares: 2));
      for (final r in some) {
        expect(more, contains(r));
      }
      expect(more.length, greaterThan(some.length));
    });
  });

  group('uncelebrated', () {
    test('returns only unlocked rewards without a party yet', () {
      final s = snap(paintings: 5);
      final fresh = uncelebrated(s, {'🦖'});
      expect(fresh.map((r) => r.emoji), ['🚀']);
      expect(uncelebrated(s, {'🦖', '🚀'}), isEmpty);
    });
  });

  group('kRewards', () {
    test('emojis are unique and do not overlap the base stamps', () {
      final emojis = kRewards.map((r) => r.emoji).toList();
      expect(emojis.toSet().length, emojis.length);
      for (final e in emojis) {
        expect(kStamps, isNot(contains(e)));
      }
    });

    test('no sticker appears in two places across all packs', () {
      // A duplicate would show the same motif twice in the picker, or make
      // an unlocked pack look like it was already available.
      final seen = <String, String>{};
      for (final pack in kStampPacks) {
        for (final emoji in pack.stamps) {
          final owner = seen[emoji];
          expect(owner, isNull,
              reason: '$emoji is in both "$owner" and "${pack.id}"');
          seen[emoji] = pack.id;
        }
      }
      for (final reward in kRewards) {
        expect(seen.containsKey(reward.emoji), isFalse,
            reason:
                'reward ${reward.emoji} also sits in pack "${seen[reward.emoji]}"');
      }
    });

    test('every pack cover emoji comes from its own stamps', () {
      for (final pack in kStampPacks) {
        expect(pack.stamps, contains(pack.emoji), reason: pack.id);
      }
    });

    test('unlock goals are positive and reachable', () {
      for (final pack in kStampPacks) {
        final unlock = pack.unlock;
        if (unlock == null) continue;
        expect(unlock.target, greaterThan(0), reason: pack.id);
      }
    });

    test('all targets are reachable positives', () {
      for (final r in kRewards) {
        expect(r.target, greaterThan(0));
        // The ceiling is a judgement about a child's patience rather than a
        // technical limit. It moved from 20 to 25 in v7.6, when the catalog
        // grew to 68 pictures and 20 stopped being the end of the road.
        expect(r.target, lessThanOrEqualTo(25));
      }
    });
  });
}
