import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/reward.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/pop_in.dart';
import '../ui/reward_text.dart';
import '../ui/sticker.dart';
import '../util/progress.dart';
import '../util/sfx.dart';

/// The achievements album: every reward sticker in one place, earned ones
/// in full color and the rest as the same mystery boxes the sticker picker
/// uses.
///
/// It is a collection, not a scoreboard — nothing here compares one child
/// to another, and every locked entry says what to do next rather than what
/// is missing.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: BlobBackground(
        gradient: PixieGradients.homeBg,
        builder: (context, _) => SafeArea(
          child: ListenableBuilder(
            listenable: Progress.instance,
            builder: (context, _) {
              final progress = Progress.instance;
              final snapshot = progress.snapshot();
              final earned = kRewards.where((r) => isUnlocked(r, snapshot));
              return Column(
                children: [
                  PixieHeader(
                    emoji: '🏆',
                    title: l10n.albumTitle,
                    accent: PixiePalette.sunshine,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        _Summary(
                          earned: earned.length,
                          total: kRewards.length,
                          streak: progress.taskStreak,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.albumStickers,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _StickerGrid(snapshot: snapshot),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.earned,
    required this.total,
    required this.streak,
  });

  final int earned;
  final int total;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StickerCard(
      color: Colors.white,
      radius: 24,
      shadowColor: PixiePalette.sunshine,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const PopIn(
            from: 0.5,
            rotateFrom: -0.1,
            child: Text('🏆', style: TextStyle(fontSize: 46)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.albumEarned(earned, total),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  // A streak only becomes a sentence once it exists —
                  // "0 days in a row" would read like a scolding.
                  streak > 0
                      ? l10n.albumStreak(streak)
                      : l10n.albumStreakNone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: PixiePalette.ink.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerGrid extends StatelessWidget {
  const _StickerGrid({required this.snapshot});

  final ProgressSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: kRewards.length,
      itemBuilder: (context, i) => _RewardTile(
        reward: kRewards[i],
        snapshot: snapshot,
        tiltIndex: i,
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.reward,
    required this.snapshot,
    required this.tiltIndex,
  });

  final StickerReward reward;
  final ProgressSnapshot snapshot;
  final int tiltIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unlocked = isUnlocked(reward, snapshot);
    return Bouncy(
      onTap: () => _explain(context, unlocked),
      playTick: false,
      minSize: 0,
      semanticLabel: unlocked
          ? l10n.albumStickerEarned
          : rewardRuleText(context, reward, snapshot),
      child: StickerCard(
        color: Colors.white,
        radius: 20,
        shadowColor:
            unlocked ? PixiePalette.sunshine : PixiePalette.ink,
        tiltIndex: tiltIndex,
        padding: const EdgeInsets.all(10),
        child: Center(
          child: unlocked
              ? Text(reward.emoji, style: const TextStyle(fontSize: 38))
              : Opacity(
                  opacity: 0.35,
                  child: Text(reward.emoji,
                      style: const TextStyle(fontSize: 38)),
                ),
        ),
      ),
    );
  }

  void _explain(BuildContext context, bool unlocked) {
    Sfx.instance.tick();
    final l10n = context.l10n;
    showKidDialog<void>(
      context: context,
      emoji: unlocked ? reward.emoji : '🔒',
      title: unlocked ? l10n.albumStickerEarned : l10n.rewardLockedTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unlocked
                ? l10n.albumStickerEarnedBody
                : rewardRuleText(context, reward, snapshot),
            textAlign: TextAlign.center,
          ),
          if (!unlocked) ...[
            const SizedBox(height: 8),
            Text(
              l10n.rewardProgress(
                  progressFor(reward, snapshot), reward.target),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
      actions: [
        Builder(
          builder: (dialogContext) => KidDialogButton(
            label: l10n.okAction,
            emoji: unlocked ? '🎉' : '💪',
            onTap: () => Navigator.pop(dialogContext),
          ),
        ),
      ],
    );
  }
}

/// Opens the album. It always shows the active kid's rewards, because
/// [Progress] is swapped when profiles are switched — the screen itself
/// stays stateless and simply listens.
Future<void> openAlbum(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AlbumScreen()),
    );
