import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../photo/photo_lineart_screen.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/music.dart';
import '../util/settings.dart';
import '../widgets/parental_gate.dart';
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

  /// One-shot staggered entrance: fade + rise, offset per slot.
  Widget _staggered(int slot, Widget child) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(0.10 * slot, 0.10 * slot + 0.55,
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
                  // Responsive sticker cards: two per row, clamped so they
                  // grow a little on tablets instead of floating in space.
                  final cardW =
                      ((constraints.maxWidth - 68) / 2).clamp(160.0, 230.0);
                  final cardH = cardW * 0.9;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _staggered(0, _Header(wave: wave)),
                        const SizedBox(height: 36),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            _staggered(
                              1,
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
                              2,
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
                              3,
                              _BigCard(
                                emoji: '📷',
                                label: context.l10n.cardPhoto,
                                gradient: PixieGradients.photo,
                                width: cardW,
                                height: cardH,
                                tiltIndex: 3,
                                onTap: () => _pickPhoto(context),
                              ),
                            ),
                            _staggered(
                              4,
                              _BigCard(
                                emoji: '🖼️',
                                label: context.l10n.cardGallery,
                                gradient: PixieGradients.gallery,
                                width: cardW,
                                height: cardH,
                                tiltIndex: 4,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const GalleryScreen()),
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
                  5,
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
                  5,
                  StickerCircleButton(
                    icon: Icons.settings_rounded,
                    tooltip: context.l10n.settingsTooltip,
                    accent: PixiePalette.grape,
                    onTap: () async {
                      if (await ParentalGate.show(context) &&
                          context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => mode == _PhotoMode.paintOver
          ? CanvasScreen(photoPath: file.path)
          : PhotoLineArtScreen(photoPath: file.path),
    ),
  );
}
