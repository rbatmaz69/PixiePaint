import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/reward.dart';
import '../models/stamp.dart';
import '../stickers/sticker_capture.dart';
import '../stickers/sticker_store.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/reward_text.dart';
import '../ui/kid_sheet.dart';
import '../ui/sticker.dart';
import '../util/anim_math.dart';
import '../util/image_io.dart';
import '../util/progress.dart';
import '../util/sfx.dart';

enum _StampSheetResult { capture }

/// Bottom sheet with the kid's own stickers and themed stamp packs; picking
/// a stamp selects the stamp tool with that motif. Locked packs and the
/// individual reward stickers appear as mystery boxes that wiggle now and
/// then and explain their goal.
Future<void> showStampPicker(
    BuildContext context, CanvasController controller) async {
  final result = await showKidSheet<_StampSheetResult>(
    context: context,
    emoji: controller.stampImage != null ? '🖼️' : controller.stampEmoji,
    title: context.l10n.toolSticker,
    child: _StampSections(controller: controller),
  );
  if (result != _StampSheetResult.capture || !context.mounted) return;

  // Capture flow, triggered after the sheet is gone.
  if (controller.isEmpty &&
      controller.backgroundImage == null &&
      controller.lineArt == null) {
    await _showInfo(context, '🖌️', context.l10n.stickerEmptyTitle,
        context.l10n.stickerEmptyBody);
    return;
  }
  if ((await StickerStore.list()).length >= StickerStore.maxStickers) {
    if (!context.mounted) return;
    await _showInfo(context, '📚', context.l10n.stickerAlbumFullTitle,
        context.l10n.stickerAlbumFullBody);
    return;
  }
  if (!context.mounted) return;
  await showStickerCapture(context, controller);
}

Future<void> _showInfo(
    BuildContext context, String emoji, String title, String body) {
  return showKidDialog<void>(
    context: context,
    emoji: emoji,
    title: title,
    body: Text(body, textAlign: TextAlign.center),
    actions: [
      Builder(
        builder: (dialogContext) => KidDialogButton(
          label: context.l10n.okAction,
          emoji: '👍',
          onTap: () => Navigator.pop(dialogContext),
        ),
      ),
    ],
  );
}

String stampPackLabel(BuildContext context, StampPack pack) =>
    switch (pack.id) {
      'basics' => context.l10n.packBasics,
      'animals2' => context.l10n.packAnimals,
      'space' => context.l10n.packSpace,
      'food' => context.l10n.packFood,
      'music' => context.l10n.packMusic,
      'party' => context.l10n.packParty,
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

  Future<List<File>> _myStickers = StickerStore.list();

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteSticker(File file) async {
    final ok = await showKidDialog<bool>(
      context: context,
      emoji: '🗑️',
      title: context.l10n.stickerDeleteTitle,
      body: Text(context.l10n.deleteBody, textAlign: TextAlign.center),
      actions: [
        Builder(
          builder: (dialogContext) => KidDialogButton(
            label: context.l10n.deleteKeep,
            emoji: '🖼️',
            onTap: () => Navigator.pop(dialogContext, false),
          ),
        ),
        Builder(
          builder: (dialogContext) => KidDialogTextButton(
            label: context.l10n.deleteAction,
            onTap: () => Navigator.pop(dialogContext, true),
          ),
        ),
      ],
    );
    if (ok != true) return;
    await StickerStore.delete(file);
    if (widget.controller.stampImagePath == file.path) {
      widget.controller.selectStamp(widget.controller.stampEmoji);
    }
    if (mounted) setState(() => _myStickers = StickerStore.list());
  }

  Future<void> _pickSticker(File file) async {
    final image = await pngBytesToImage(await file.readAsBytes());
    // The sheet can be swiped away while the PNG decodes.
    if (!mounted) return image.dispose();
    widget.controller.selectImageStamp(file.path, image);
    Navigator.of(context).pop();
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

    // The kid's own stickers, with the "make a sticker" tile first.
    children.add(_header(context, '🖼️', context.l10n.myStickersSection));
    children.add(FutureBuilder<List<File>>(
      future: _myStickers,
      builder: (context, snapshot) {
        final files = snapshot.data ?? const <File>[];
        return _grid([
          _MakeStickerTile(
            onTap: () =>
                Navigator.of(context).pop(_StampSheetResult.capture),
          ),
          for (final file in files)
            _MyStickerTile(
              file: file,
              selected: controller.stampImagePath == file.path,
              onTap: () => _pickSticker(file),
              onLongPress: () => _confirmDeleteSticker(file),
            ),
        ]);
      },
    ));

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

/// Dashed-feel "make your own sticker" tile: big plus on a soft tint.
class _MakeStickerTile extends StatelessWidget {
  const _MakeStickerTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.stickerCaptureTitle,
      child: Bouncy(
        playTick: false,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDBD2C3), width: 2),
          ),
          child: const Center(
            child: Text('➕', style: TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }
}

/// One of the kid's own stickers; long-press to throw it away.
class _MyStickerTile extends StatelessWidget {
  const _MyStickerTile({
    required this.file,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final File file;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Bouncy(
        playTick: false,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: stickerSelectionDecoration(
            selected: selected,
            accent: const Color(0xFFFFB020),
          ),
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
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
    final rule = rewardRuleText(context, reward, snapshot);
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
