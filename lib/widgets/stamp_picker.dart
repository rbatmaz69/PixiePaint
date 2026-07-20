import 'dart:math';

import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/reward.dart';
import '../models/stamp.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/kid_sheet.dart';
import '../util/anim_math.dart';
import '../util/progress.dart';
import '../util/sfx.dart';

/// Bottom sheet with a grid of emoji stamps; picking one selects the stamp
/// tool with that motif. Reward stickers appear at the end — locked ones as
/// mystery boxes that wiggle now and then and explain how to earn them.
Future<void> showStampPicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: controller.stampEmoji,
    title: context.l10n.toolSticker,
    child: _StampGrid(controller: controller),
  );
}

class _StampGrid extends StatefulWidget {
  const _StampGrid({required this.controller});

  final CanvasController controller;

  @override
  State<_StampGrid> createState() => _StampGridState();
}

class _StampGridState extends State<_StampGrid>
    with SingleTickerProviderStateMixin {
  /// One shared ticker for all locked tiles' wiggle. Bound to the sheet's
  /// (short) lifetime — same acceptability class as LoadingPixie.
  late final AnimationController _wiggle = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GridView.builder(
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
        final rewardIndex = i - kStamps.length;
        final reward = kRewards[rewardIndex];
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
        return _LockedRewardTile(
          reward: reward,
          index: rewardIndex,
          wiggle: _wiggle,
        );
      },
    );
  }
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
/// Wags gently now and then (shared ticker), shakes "no" when tapped, then
/// explains the goal in kid terms.
class _LockedRewardTile extends StatefulWidget {
  const _LockedRewardTile({
    required this.reward,
    required this.index,
    required this.wiggle,
  });

  final StickerReward reward;
  final int index;
  final Animation<double> wiggle;

  @override
  State<_LockedRewardTile> createState() => _LockedRewardTileState();
}

class _LockedRewardTileState extends State<_LockedRewardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _onTap() {
    _shake.forward(from: 0);
    _explain(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Bouncy(
      playTick: false,
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.wiggle, _shake]),
        builder: (context, child) {
          final t = _shake.value;
          final dx = _shake.isAnimating ? sin(t * 3 * pi) * 4 * (1 - t) : 0.0;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.rotate(
              angle: lockedWiggleAngle(widget.wiggle.value, widget.index),
              child: child,
            ),
          );
        },
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
      ),
    );
  }

  void _explain(BuildContext context) {
    Sfx.instance.tick();
    final reward = widget.reward;
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
