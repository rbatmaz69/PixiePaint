import 'dart:async';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/pixie_palette.dart';
import '../ui/pop_in.dart';
import '../ui/sticker.dart';
import '../util/settings.dart';
import '../util/sfx.dart';
import 'page_picker_screen.dart';

/// Shown once, before the home screen ever appears.
///
/// Three cards, and "skip" is on every one of them from the start: a child
/// who wants to paint right now is allowed to, and nothing here is worth
/// making them sit through. The last card hands over to the picture picker
/// rather than the home screen — the first impression should be painting,
/// not a menu.
///
/// The third card is for the adult who will be handed the tablet, and is
/// the only text on this screen written in a grown-up register.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  int _index = 0;

  static const _cardCount = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await Settings.instance.markWelcomeSeen();
    if (!mounted) return;
    unawaited(Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PagePickerScreen()),
    ));
  }

  void _next() {
    if (_index >= _cardCount - 1) {
      _finish();
      return;
    }
    Sfx.instance.tick();
    _pages.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLast = _index == _cardCount - 1;
    return Scaffold(
      body: BlobBackground(
        gradient: PixieGradients.homeBg,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                  child: Bouncy(
                    onTap: _finish,
                    semanticLabel: l10n.welcomeSkip,
                    child: Text(
                      l10n.welcomeSkip,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: PixiePalette.ink.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    _Card(
                      emoji: '🧚',
                      title: l10n.welcomeHelloTitle,
                      body: l10n.welcomeHelloBody,
                      accent: PixiePalette.grape,
                    ),
                    _Card(
                      emoji: '🖍️',
                      title: l10n.welcomePaintTitle,
                      body: l10n.welcomePaintBody,
                      accent: PixiePalette.sunshine,
                    ),
                    _Card(
                      emoji: '👨‍👩‍👧',
                      title: l10n.welcomeParentsTitle,
                      body: l10n.welcomeParentsBody,
                      accent: PixiePalette.mint,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _cardCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? PixiePalette.grape
                            : PixiePalette.ink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                child: KidDialogButton(
                  label: isLast ? l10n.welcomeStart : l10n.welcomeNext,
                  emoji: isLast ? '🎨' : '👉',
                  sticker: true,
                  gradient: PixieGradients.coloring,
                  onTap: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.emoji,
    required this.title,
    required this.body,
    required this.accent,
  });

  final String emoji;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopIn(
              from: 0.4,
              rotateFrom: -0.12,
              duration: const Duration(milliseconds: 620),
              child: Text(emoji, style: const TextStyle(fontSize: 88)),
            ),
            const SizedBox(height: 24),
            StickerCard(
              color: Colors.white,
              radius: 24,
              shadowColor: accent,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: PixiePalette.ink.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
