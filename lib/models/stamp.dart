import 'reward.dart';

/// Emoji stamp motifs — zero-asset, colorful, scale to any size via
/// TextPainter. If a device renders one monochrome, just swap it out here.
const List<String> kStamps = [
  '⭐', '🌟', '✨', '❤️', '💖', '🌈', '🦄', '🐶', '🐱', '🐰',
  '🦋', '🐞', '🐢', '🌸', '🌻', '🍄', '🍎', '⚽', '🎈', '👑',
];

/// Stamp sizes in canvas px, indexed by the shared sizeIndex (S/M/L).
const List<double> kStampSizes = [140, 220, 340];

/// A themed group of stamps in the picker. Packs with an [unlock] goal show
/// as a mystery tile until the goal is reached (no celebration party — they
/// simply appear, unlike the individual kRewards stickers).
///
/// Emoji must not overlap kStamps or kRewards and must render in color on
/// both platforms.
class StampPack {
  final String id;
  final String emoji;
  final List<String> stamps;
  final StickerReward? unlock;

  const StampPack({
    required this.id,
    required this.emoji,
    required this.stamps,
    this.unlock,
  });
}

const List<StampPack> kStampPacks = [
  StampPack(id: 'basics', emoji: '⭐', stamps: kStamps),
  StampPack(
    id: 'animals2',
    emoji: '🦊',
    stamps: ['🦊', '🐸', '🐼', '🦁', '🐷', '🐙', '🦉', '🐝', '🦕', '🐠'],
  ),
  StampPack(
    id: 'space',
    emoji: '🪐',
    stamps: ['🪐', '🌙', '☀️', '🌍', '🌠', '👾', '🤖', '🛰️', '☄️', '🔭'],
    unlock: StickerReward('🪐', RewardGoalKind.paintings, 10),
  ),
  StampPack(
    id: 'food',
    emoji: '🍩',
    stamps: ['🍩', '🍦', '🍓', '🍌', '🍕', '🧁', '🍭', '🥕', '🍪', '🍉'],
    unlock: StickerReward('🍩', RewardGoalKind.tools, 7),
  ),
  StampPack(
    id: 'music',
    emoji: '🎵',
    stamps: ['🎵', '🎶', '🥁', '🎸', '🎺', '🎹', '🎻', '🪗', '🎤', '🎧'],
    unlock: StickerReward('🎵', RewardGoalKind.tracing, 5),
  ),
  StampPack(
    id: 'vehicles',
    emoji: '🚗',
    stamps: ['🚗', '🚒', '🚜', '🚂', '✈️', '🚁', '⛵', '🚲', '🛶', '🚌'],
    unlock: StickerReward('🚗', RewardGoalKind.paintings, 14),
  ),
  StampPack(
    id: 'party',
    emoji: '🎉',
    stamps: ['🎉', '🎊', '🎂', '🎁', '🪅', '🎪', '🎯', '🏆', '🥳', '🍿'],
    unlock: StickerReward('🎉', RewardGoalKind.cbn, 3),
  ),
];
