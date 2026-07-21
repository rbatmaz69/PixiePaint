import 'dart:math';

import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/reward.dart';
import '../models/stamp.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/kid_sheet.dart';
import '../ui/sticker.dart';
import '../util/anim_math.dart';
import '../util/progress.dart';
import '../util/sfx.dart';

/// Bottom sheet with themed stamp packs; picking a stamp selects the stamp
/// tool with that motif. Locked packs and the individual reward stickers
/// appear as mystery boxes that wiggle now and then and explain their goal.
Future<void> showStampPicker(
    BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: controller.stampEmoji,
    title: context.l10n.toolSticker,
    child: _StampSections(controller: controller),
  );
}

String stampPackLabel(BuildContext context, StampPack pack) =>
    switch (pack.id) {
      'basics' => context.l10n.packBasics,
      'animals2' => context.l10n.packAnimals,
      'space' => context.l10n.packSpace,
      'food' => context.l10n.packFood,
      'vehicles' => context.l10n.packVehicles,
      _ => pack.id,
    };

class _StampSections extends StatefulWidget {
  const _StampSections({required this.controller});

  final CanvasController controller;

  @override
  State<_StampSections> createState() => _StampSectionsState();
}

class _StampSectionsState extends State<_StampSections>
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

  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 80,
    mainAxisSpacing: 6,
    crossAxisSpacing: 6,
  );

  Widget _header(BuildContext context, String emoji, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _grid(List<Widget> tiles) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: _gridDelegate,
      children: tiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    var lockedIndex = 0; // staggers the wiggle across all locked tiles

    Widget stampTile(String emoji) => _StampTile(
          emoji: emoji,
          selected: controller.stampEmoji == emoji,
          onTap: () {
            controller.selectStamp(emoji);
            Navigator.of(context).pop();
          },
        );

    final children = <Widget>[];
    for (final pack in kStampPacks) {
      children.add(_header(
          context,
          pack.unlock != null &&
                  !Progress.instance.isRewardUnlocked(pack.unlock!)
              ? '🔒'
              : pack.emoji,
          stampPackLabel(context, pack)));
      final unlock = pack.unlock;
      if (unlock != null && !Progress.instance.isRewardUnlocked(unlock)) {
        children.add(_grid([
          _LockedRewardTile(
              reward: unlock, index: lockedIndex++, wiggle: _wiggle),
        ]));
        continue;
      }
      children.add(_grid([for (final emoji in pack.stamps) stampTile(emoji)]));
    }

    // Individual reward stickers, earned one by one.
    children.add(_header(context, '🎁', context.l10n.packRewards));
    children.add(_grid([
      for (final reward in kRewards)
        if (Progress.instance.isRewardUnlocked(reward))
          stampTile(reward.emoji)
        else
          _LockedRewardTile(
              reward: reward, index: lockedIndex++, wiggle: _wiggle),
    ]));

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: children,
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
        decoration: stickerSelectionDecoration(
          selected: selected,
          accent: const Color(0xFFFFB020),
        ),
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: selected ? 40 : 36)),
        ),
      ),
    );
  }
}

/// Mystery box for a still-locked reward sticker or stamp pack: big ❓ with a
/// lock badge. Wags gently now and then (shared ticker), shakes "no" when
/// tapped, then explains the goal in kid terms.
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
            color: const Color(0xFFF5F0E8),
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
