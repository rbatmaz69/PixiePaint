import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/reward.dart';
import '../models/stamp.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/kid_sheet.dart';
import '../util/progress.dart';
import '../util/sfx.dart';

/// Bottom sheet with a grid of emoji stamps; picking one selects the stamp
/// tool with that motif. Reward stickers appear at the end — locked ones as
/// mystery boxes that explain how to earn them.
Future<void> showStampPicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: controller.stampEmoji,
    title: context.l10n.toolSticker,
    child: GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 80,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: kStamps.length + kRewards.length,
      itemBuilder: (context, i) {
        if (i < kStamps.length) {
          return _StampTile(
            emoji: kStamps[i],
            selected: controller.stampEmoji == kStamps[i],
            onTap: () {
              controller.selectStamp(kStamps[i]);
              Navigator.of(context).pop();
            },
          );
        }
        final reward = kRewards[i - kStamps.length];
        if (Progress.instance.isRewardUnlocked(reward)) {
          return _StampTile(
            emoji: reward.emoji,
            selected: controller.stampEmoji == reward.emoji,
            onTap: () {
              controller.selectStamp(reward.emoji);
              Navigator.of(context).pop();
            },
          );
        }
        return _LockedRewardTile(reward: reward);
      },
    ),
  );
}

class _StampTile extends StatelessWidget {
  const _StampTile(
      {required this.emoji, required this.selected, required this.onTap});

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      playTick: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: selected ? 40 : 36)),
        ),
      ),
    );
  }
}

/// Mystery box for a still-locked reward sticker: big ❓ with a lock badge.
/// Tapping explains the goal in kid terms instead of selecting.
class _LockedRewardTile extends StatelessWidget {
  const _LockedRewardTile({required this.reward});

  final StickerReward reward;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Bouncy(
      playTick: false,
      onTap: () => _explain(context),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('❓',
                style: TextStyle(
                    fontSize: 32,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7))),
            const Positioned(
              right: 6,
              bottom: 6,
              child: Text('🔒', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _explain(BuildContext context) {
    Sfx.instance.tick();
    final snapshot = Progress.instance.snapshot();
    final remaining = remainingFor(reward, snapshot);
    final rule = switch (reward.kind) {
      RewardGoalKind.paintings =>
        context.l10n.rewardRulePaintings(remaining),
      RewardGoalKind.tools => context.l10n.rewardRuleTools(remaining),
      RewardGoalKind.shares => context.l10n.rewardRuleShares,
    };
    showKidDialog<void>(
      context: context,
      emoji: '🔒',
      title: context.l10n.rewardLockedTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rule, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            context.l10n
                .rewardProgress(progressFor(reward, snapshot), reward.target),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (dialogContext) => KidDialogButton(
            label: context.l10n.okAction,
            emoji: '💪',
            onTap: () => Navigator.pop(dialogContext),
          ),
        ),
      ],
    );
  }
}
