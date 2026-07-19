import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../canvas/canvas_screen.dart';
import '../photo/photo_lineart_screen.dart';
import '../widgets/parental_gate.dart';
import 'gallery_screen.dart';
import 'page_picker_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎨 PixiePaint',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _BigCard(
                          emoji: '🖍️',
                          label: 'Ausmalen',
                          color: const Color(0xFFFFF59D),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PagePickerScreen()),
                          ),
                        ),
                        _BigCard(
                          emoji: '✏️',
                          label: 'Frei malen',
                          color: const Color(0xFFB3E5FC),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CanvasScreen()),
                          ),
                        ),
                        _BigCard(
                          emoji: '📷',
                          label: 'Foto anmalen',
                          color: const Color(0xFFFFCCBC),
                          onTap: () => _pickPhoto(context),
                        ),
                        _BigCard(
                          emoji: '🖼️',
                          label: 'Meine Bilder',
                          color: const Color(0xFFC8E6C9),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const GalleryScreen()),
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
              child: IconButton(
                iconSize: 28,
                onPressed: () async {
                  if (await ParentalGate.show(context) && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  }
                },
                icon: Icon(Icons.settings_rounded,
                    color: Colors.black.withValues(alpha: 0.3)),
                tooltip: 'Einstellungen (für Eltern)',
              ),
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
  final mode = await showDialog<_PhotoMode>(
    context: context,
    builder: (context) => SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Was machen wir mit dem Foto?',
          textAlign: TextAlign.center),
      contentPadding: const EdgeInsets.all(20),
      children: [
        _PhotoModeButton(
          emoji: '🖌️',
          label: 'Foto anmalen',
          onTap: () => Navigator.of(context).pop(_PhotoMode.paintOver),
        ),
        const SizedBox(height: 12),
        _PhotoModeButton(
          emoji: '✨',
          label: 'Ausmalbild zaubern',
          onTap: () => Navigator.of(context).pop(_PhotoMode.lineArt),
        ),
      ],
    ),
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

class _PhotoModeButton extends StatelessWidget {
  const _PhotoModeButton(
      {required this.emoji, required this.label, required this.onTap});

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(32),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: SizedBox(
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
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
