import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import '../models/reward.dart';

/// The one place that turns a reward goal into a sentence a child can act
/// on ("Finish 2 more pictures!"). Shared by the sticker picker and the
/// achievements album so the same locked sticker never explains itself two
/// different ways.
String rewardRuleText(
  BuildContext context,
  StickerReward reward,
  ProgressSnapshot snapshot,
) {
  final remaining = remainingFor(reward, snapshot);
  return switch (reward.kind) {
    RewardGoalKind.paintings => context.l10n.rewardRulePaintings(remaining),
    RewardGoalKind.tools => context.l10n.rewardRuleTools(remaining),
    RewardGoalKind.shares => context.l10n.rewardRuleShares,
    RewardGoalKind.tracing => context.l10n.rewardRuleTrace(remaining),
    RewardGoalKind.cbn => context.l10n.rewardRuleCbn(remaining),
    RewardGoalKind.tasks => context.l10n.rewardRuleTasks(remaining),
  };
}
