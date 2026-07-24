import 'package:flutter/material.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/daily_task.dart';
import '../ui/app_theme.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/kid_sheet.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/progress.dart';
import '../util/sfx.dart';
import 'confetti_burst.dart';

/// Today's painting prompt: big and readable, with "let's go" (into free
/// drawing) and an honest self-check "done" button — no fake detection.
Future<void> showDailyTaskSheet(BuildContext context, DailyTask task) async {
  final lang = Localizations.localeOf(context).languageCode;
  final today = dayKey(DateTime.now());
  final alreadyDone = Progress.instance.isTaskDoneOn(today);

  final markDone = await showKidSheet<bool>(
    context: context,
    emoji: task.emoji,
    title: context.l10n.dailyTaskTitle,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            task.titleFor(lang),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Builder(
            builder: (sheetContext) => KidDialogButton(
              emoji: '🖌️',
              label: context.l10n.dailyTaskGo,
              gradient: PixieGradients.freeDraw,
              onTap: () {
                Navigator.pop(sheetContext, false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CanvasScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          if (!alreadyDone)
            Builder(
              builder: (sheetContext) => KidDialogButton(
                emoji: '✅',
                label: context.l10n.dailyTaskDone,
                gradient: PixieGradients.gallery,
                onTap: () => Navigator.pop(sheetContext, true),
              ),
            )
          else
            Text(
              context.l10n.dailyTaskAlreadyDone,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    ),
  );

  if (markDone != true || !context.mounted) return;
  Progress.instance.registerDailyTaskDone(today);
  Sfx.instance.tada();
  showConfetti(context, scale: ConfettiScale.small);
}

/// Home-screen pill: today's emoji and prompt, with a check badge once the
/// kid has ticked it off.
class DailyTaskBanner extends StatelessWidget {
  const DailyTaskBanner({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final task = taskForDate(DateTime.now());
    return ListenableBuilder(
      listenable: Progress.instance,
      builder: (context, _) {
        final done = Progress.instance.isTaskDoneOn(dayKey(DateTime.now()));
        return Bouncy(
          onTap: () => showDailyTaskSheet(context, task),
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: PixieTokens.softShadow(PixiePalette.sunshine),
            ),
            child: Row(
              children: [
                StickerEmoji(task.emoji,
                    size: 26, shadowColor: PixiePalette.sunshine),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.dailyTaskTitle,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                      ),
                      Text(
                        task.titleFor(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (done) const Text('✅', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),
        );
      },
    );
  }
}
