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
import '../ui/soft_card.dart';
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
                child: SingleChildScrollView(
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
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const PagePickerScreen()),
                              ),
                            ),
                          ),
                          _staggered(
                            2,
                            _BigCard(
                              emoji: '✏️',
                              label: context.l10n.cardFreeDraw,
                              gradient: PixieGradients.freeDraw,
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
                              onTap: () => _pickPhoto(context),
                            ),
                          ),
                          _staggered(
                            4,
                            _BigCard(
                              emoji: '🖼️',
                              label: context.l10n.cardGallery,
                              gradient: PixieGradients.gallery,
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
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _staggered(
                  5,
                  Bouncy(
                    onTap: () async {
                      if (await ParentalGate.show(context) &&
                          context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Tooltip(
                        message: context.l10n.settingsTooltip,
                        child: Icon(Icons.settings_rounded,
                            size: 26,
                            color: Colors.black.withValues(alpha: 0.4)),
                      ),
                    ),
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
          const Text('🎨', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 4),
          Text(
            'PixiePaint',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
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
  });

  final String emoji;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: SoftCard(
        gradient: gradient,
        width: 200,
        height: 180,
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
