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
import '../ui/entrance.dart';
import '../ui/kid_dialog.dart';
import '../ui/motion.dart';
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

/// One tile in the big grid. Everything a card differs in and nothing else —
/// the size comes from the layout, the entrance slot from its position.
class _CardSpec {
  const _CardSpec({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.tiltIndex,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Gradient gradient;
  final int tiltIndex;
  final VoidCallback onTap;
}

/// Where the cards start in the entrance cascade: header, continue card and
/// daily-task banner come first.
const int _firstCardSlot = 3;

/// The two floating buttons in the corners bring up the rear. Well past the
/// cards on purpose — [buildEntrance] clamps the stagger at slot 10, so they
/// simply arrive with the last of them rather than before any.
const int _chromeSlot = 11;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, EntranceMixin {
  /// The cascade: header, continue card, daily-task banner, the cards and
  /// the two chrome buttons. [EntranceMixin] does the work.
  Widget _staggered(int slot, Widget child) => entrance(slot, child);

  /// How far the grid has been scrolled, handed to [BlobBackground] so the
  /// paper drifts a fraction of what the stickers on it do. A notifier
  /// rather than setState: only the blob layer needs to hear about it, and
  /// rebuilding the whole grid on every scroll frame would be absurd.
  final ValueNotifier<double> _scrollY = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollY.dispose();
    super.dispose();
  }

  /// The grid, in the order it is shown. A list rather than eight spelled-out
  /// widgets because the eight only ever differed in these five fields — and
  /// because the entrance slots then come from the position instead of being
  /// typed by hand, which is how gallery, album and two-painter ended up
  /// sharing one and flying in together.
  List<_CardSpec> _cards(BuildContext context) {
    void open(Widget Function() screen) {
      unawaited(Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen()),
      ));
    }

    return [
      _CardSpec(
        emoji: '🖍️',
        label: context.l10n.cardColoring,
        gradient: PixieGradients.coloring,
        tiltIndex: 1,
        onTap: () => open(PagePickerScreen.new),
      ),
      _CardSpec(
        emoji: '✏️',
        label: context.l10n.cardFreeDraw,
        gradient: PixieGradients.freeDraw,
        tiltIndex: 2,
        onTap: () => open(CanvasScreen.new),
      ),
      _CardSpec(
        emoji: '🏞️',
        label: context.l10n.cardScenes,
        gradient: PixieGradients.scenes,
        tiltIndex: 3,
        onTap: () => open(ScenePickerScreen.new),
      ),
      _CardSpec(
        emoji: '📷',
        label: context.l10n.cardPhoto,
        gradient: PixieGradients.photo,
        tiltIndex: 4,
        onTap: () => _pickPhoto(context),
      ),
      _CardSpec(
        emoji: '✍️',
        label: context.l10n.cardTrace,
        gradient: PixieGradients.trace,
        tiltIndex: 5,
        onTap: () => open(TracePickerScreen.new),
      ),
      _CardSpec(
        emoji: '🖼️',
        label: context.l10n.cardGallery,
        gradient: PixieGradients.gallery,
        tiltIndex: 6,
        onTap: () => open(GalleryScreen.new),
      ),
      _CardSpec(
        emoji: '🏆',
        label: context.l10n.albumTitle,
        gradient: PixieGradients.rewards,
        tiltIndex: 4,
        onTap: () => openAlbum(context),
      ),
      // Two painters need the room of a tablet.
      if (MediaQuery.sizeOf(context).shortestSide >= 600)
        _CardSpec(
          emoji: '🤝',
          label: context.l10n.cardTwoPainter,
          gradient: PixieGradients.freeDraw,
          tiltIndex: 2,
          onTap: () => open(TwoPainterScreen.new),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        gradient: PixieGradients.homeBg,
        parallax: _scrollY,
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
                  // The label grows with the system font, so the card has
                  // to. A fixed 0.9 * width overflowed at the largest text
                  // size the app allows — the tiles simply get taller, the
                  // page scrolls, and the grid stays two across.
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final cardH = cardW * 0.9 + (textScale - 1).clamp(0, 1) * 56;
                  return NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.axis == Axis.vertical) {
                        _scrollY.value = n.metrics.pixels;
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _staggered(0, _Header(wave: wave)),
                          const SizedBox(height: PixieTokens.gapLarge),
                          _staggered(1, ContinueCard(width: rowW)),
                          _staggered(2, DailyTaskBanner(width: rowW)),
                          const SizedBox(height: PixieTokens.gapLarge),
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final (i, card)
                                  in _cards(context).indexed)
                                _staggered(
                                  _firstCardSlot + i,
                                  _BigCard(
                                    spec: card,
                                    width: cardW,
                                    height: cardH,
                                    wave: wave,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: _staggered(
                  _chromeSlot,
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
                  _chromeSlot + 1,
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
            child: StickerPill(
              padding: const EdgeInsets.symmetric(
                  horizontal: PixieTokens.gap, vertical: PixieTokens.gapSmall),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(profile.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: PixieTokens.gapSmall),
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
          const SizedBox(height: PixieTokens.gapSmall),
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
    required this.spec,
    required this.width,
    required this.height,
    required this.wave,
  });

  final _CardSpec spec;
  final double width;
  final double height;

  /// The blob background's 28-second loop, borrowed. The header has swayed
  /// on it since v8.2; the cards were the only stickers on the page holding
  /// perfectly still. Their own ticker would have been eight more of them.
  final Animation<double> wave;

  @override
  Widget build(BuildContext context) {
    final Widget card = Bouncy(
      onTap: spec.onTap,
      child: StickerCard(
        gradient: spec.gradient,
        width: width,
        height: height,
        tiltIndex: spec.tiltIndex,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The emoji is the part that gives way when the system font is
            // large: the word is what a reader needs, the picture still
            // reads at a smaller size.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(spec.emoji, style: const TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: PixieTokens.gap),
            Flexible(
              child: Text(
                spec.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    if (reducedMotion(context)) return card;
    return AnimatedBuilder(
      animation: wave,
      // The card paints once and is only re-composited as it drifts — the
      // whole point of borrowing a ticker instead of adding one.
      child: RepaintBoundary(child: card),
      builder: (context, child) {
        // Each card takes its phase from its tilt slot, so the eight breathe
        // out of step. In step they would read as the page moving.
        final t = 2 * pi * wave.value + spec.tiltIndex * 0.8;
        return Transform.translate(
          offset: Offset(sin(t) * 1.5, cos(t * 1.3) * 2.5),
          child: child,
        );
      },
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
    actions: (pop) => [
      KidDialogButton(
        emoji: '🖌️',
        label: context.l10n.photoModePaint,
        gradient: PixieGradients.photo,
        onTap: () => Navigator.pop(pop, _PhotoMode.paintOver),
      ),
      KidDialogButton(
        emoji: '✨',
        label: context.l10n.photoModeLineArt,
        gradient: PixieGradients.freeDraw,
        onTap: () => Navigator.pop(pop, _PhotoMode.lineArt),
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
