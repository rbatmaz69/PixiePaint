import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../canvas/canvas_screen.dart';
import '../canvas/two_painter_screen.dart';
import '../l10n/l10n.dart';
import '../photo/photo_lineart_screen.dart';
import '../trace/trace_picker_screen.dart';
import 'scene_picker_screen.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/music.dart';
import '../util/profiles.dart';
import '../util/settings.dart';
import '../widgets/daily_task_sheet.dart';
import '../widgets/parental_gate.dart';
import '../widgets/profile_sheet.dart';
import 'album_screen.dart';
import 'continue_card.dart';
import 'gallery_screen.dart';
import 'page_picker_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Number of entrance slots: header, continue card, daily-task banner,
  /// six cards and the two chrome buttons. The step is derived from it so adding a card keeps
  /// the whole cascade inside the controller's run instead of piling up at
  /// the clamp.
  static const int _slotCount = 11;
  static const double _slotStep = 0.45 / (_slotCount - 1);

  /// One-shot staggered entrance: fade + rise, offset per slot.
  Widget _staggered(int slot, Widget child) {
    final start = (_slotStep * slot).clamp(0.0, 0.45);
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, (start + 0.55).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        gradient: PixieGradients.homeBg,
        builder: (context, wave) => SafeArea(
          child: Stack(
            children: [
              Center(
                child: LayoutBuilder(builder: (context, constraints) {
                  // Two cards per row. 48 is the horizontal padding below,
                  // 20 the Wrap spacing — the row width the cards have to
                  // share. The lower bound must stay under half of that on
                  // the narrowest phones (~360 dp), otherwise the clamp
                  // pushes the second card onto its own line and the grid
                  // collapses into a six-item list.
                  final rowW = constraints.maxWidth - 48;
                  final cardW = ((rowW - 20) / 2).clamp(128.0, 230.0);
                  final cardH = cardW * 0.9;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _staggered(0, _Header(wave: wave)),
                        const SizedBox(height: 20),
                        _staggered(1, ContinueCard(width: rowW)),
                        _staggered(2, DailyTaskBanner(width: rowW)),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            _staggered(
                              3,
                              _BigCard(
                                emoji: '🖍️',
                                label: context.l10n.cardColoring,
                                gradient: PixieGradients.coloring,
                                width: cardW,
                                height: cardH,
                                tiltIndex: 1,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PagePickerScreen()),
                                ),
                              ),
                            ),
                            _staggered(
                              4,
                              _BigCard(
                                emoji: '✏️',
                                label: context.l10n.cardFreeDraw,
                                gradient: PixieGradients.freeDraw,
                                width: cardW,
                                height: cardH,
                                tiltIndex: 2,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const CanvasScreen()),
                                ),
                              ),
                            ),
                            _staggered(
                              5,
                              _BigCard(
                                emoji: '🏞️',
                                label: context.l10n.cardScenes,
                                gradient: PixieGradients.scenes,
                                width: cardW,
                                height: cardH,
                                tiltIndex: 3,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ScenePickerScreen()),
                                ),
                              ),
                            ),
                            _staggered(
                              6,
                              _BigCard(
                                emoji: '📷',
                                label: context.l10n.cardPhoto,
                                gradient: PixieGradients.photo,
                                width: cardW,
                                height: cardH,
                                tiltIndex: 4,
                                onTap: () => _pickPhoto(context),
                              ),
                            ),
                            _staggered(
                              7,
                              _BigCard(
                                emoji: '✍️',
                                label: context.l10n.cardTrace,
                                gradient: PixieGradients.trace,
                                width: cardW,
                                height: cardH,
                                tiltIndex: 5,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const TracePickerScreen()),
                                ),
                              ),
                            ),
                            _staggered(
                              8,
                              _BigCard(
                                emoji: '🖼️',
                                label: context.l10n.cardGallery,
                                gradient: PixieGradients.gallery,
                                width: cardW,
                                height: cardH,
                                tiltIndex: 6,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const GalleryScreen()),
                                ),
                              ),
                            ),
                            _staggered(
                              8,
                              _BigCard(
                                emoji: '🏆',
                                label: context.l10n.albumTitle,
                                gradient: PixieGradients.rewards,
                                width: cardW,
                                height: cardH,
                                tiltIndex: 4,
                                onTap: () => openAlbum(context),
                              ),
                            ),
                            // Two painters need the room of a tablet.
                            if (MediaQuery.sizeOf(context).shortestSide >= 600)
                              _staggered(
                                8,
                                _BigCard(
                                  emoji: '🤝',
                                  label: context.l10n.cardTwoPainter,
                                  gradient: PixieGradients.freeDraw,
                                  width: cardW,
                                  height: cardH,
                                  tiltIndex: 2,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const TwoPainterScreen()),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: _staggered(
                  9,
                  ListenableBuilder(
                    listenable: Settings.instance,
                    builder: (context, _) {
                      final on = Settings.instance.musicOn;
                      return StickerCircleButton(
                        icon: on
                            ? Icons.music_note_rounded
                            : Icons.music_off_rounded,
                        tooltip: context.l10n.musicTitle,
                        accent: on
                            ? PixiePalette.bubblegum
                            : PixiePalette.grape,
                        onTap: () async {
                          final next = !Settings.instance.musicOn;
                          await Settings.instance.update(musicOn: next);
                          await Music.instance.setOn(next);
                        },
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _staggered(
                  10,
                  StickerCircleButton(
                    icon: Icons.settings_rounded,
                    tooltip: context.l10n.settingsTooltip,
                    accent: PixiePalette.grape,
                    onTap: () async {
                      if (await ParentalGate.show(context) &&
                          context.mounted) {
                        unawaited(Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        ));
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 72,
                right: 72,
                child: _staggered(0, const _ProfileChip()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top-center pill showing the active kid; tapping opens the switcher. Kids
/// can switch freely — only managing profiles sits behind the gate.
class _ProfileChip extends StatelessWidget {
  const _ProfileChip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListenableBuilder(
        listenable: ProfileStore.instance,
        builder: (context, _) {
          final profile = ProfileStore.instance.active;
          return Bouncy(
            onTap: () => showProfileSheet(context),
            playTick: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: PixieTokens.softShadow(PixiePalette.grape),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(profile.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      profile.name.isEmpty
                          ? context.l10n.profileDefaultName
                          : profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// App title with the palette emoji; sways very slowly (±1.5°) on the blob
/// wave — no extra ticker.
class _Header extends StatelessWidget {
  const _Header({required this.wave});

  final Animation<double> wave;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: wave,
      builder: (context, child) => Transform.rotate(
        angle: sin(2 * pi * wave.value * 3) * 0.026,
        child: child,
      ),
      child: Column(
        children: [
          const StickerEmoji('🎨',
              size: 56, tiltIndex: 2, shadowColor: PixiePalette.grape),
          const SizedBox(height: 10),
          Text(
            'PixiePaint',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: PixiePalette.grape,
                ),
          ),
        ],
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.onTap,
    required this.width,
    required this.height,
    required this.tiltIndex,
  });

  final String emoji;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  final double width;
  final double height;
  final int tiltIndex;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: StickerCard(
        gradient: gradient,
        width: width,
        height: height,
        tiltIndex: tiltIndex,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PhotoMode { paintOver, lineArt }

/// Photo painting leaves the kid-safe context (system photo picker), so it
/// sits behind the parental gate.
Future<void> _pickPhoto(BuildContext context) async {
  if (!await ParentalGate.show(context)) return;
  final file = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (file == null || !context.mounted) return;
  final mode = await showKidDialog<_PhotoMode>(
    context: context,
    emoji: '📷',
    title: context.l10n.photoDialogTitle,
    actions: [
      Builder(
        builder: (context) => KidDialogButton(
          emoji: '🖌️',
          label: context.l10n.photoModePaint,
          gradient: PixieGradients.photo,
          onTap: () => Navigator.of(context).pop(_PhotoMode.paintOver),
        ),
      ),
      Builder(
        builder: (context) => KidDialogButton(
          emoji: '✨',
          label: context.l10n.photoModeLineArt,
          gradient: PixieGradients.freeDraw,
          onTap: () => Navigator.of(context).pop(_PhotoMode.lineArt),
        ),
      ),
    ],
  );
  if (mode == null || !context.mounted) return;
  unawaited(Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => mode == _PhotoMode.paintOver
          ? CanvasScreen(photoPath: file.path)
          : PhotoLineArtScreen(photoPath: file.path),
    ),
  ));
}
