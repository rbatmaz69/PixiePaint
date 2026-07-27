import 'dart:async';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/kid_dialog.dart';
import '../ui/motion.dart';
import '../ui/page_dots.dart';
import '../ui/pixie_palette.dart';
import '../ui/pop_in.dart';
import '../ui/sticker.dart';
import '../util/settings.dart';
import '../util/sfx.dart';
import 'home_screen.dart';
import 'page_picker_screen.dart';

/// Shown once, before the home screen ever appears.
///
/// Three cards, and "skip" is on every one of them from the start: a child
/// who wants to paint right now is allowed to, and nothing here is worth
/// making them sit through. The last card hands over to the picture picker
/// rather than the home screen — the first impression should be painting,
/// not a menu.
///
/// It does so by putting the home screen underneath and the picker on top,
/// which is not the same as replacing the welcome with the picker. That is
/// what it used to do, and the picker became the *root*: its back arrow
/// popped the last route and left an empty navigator, and the gallery, the
/// rewards, the profile chip, the music toggle, the settings and "carry on
/// painting" were unreachable for the whole first session.
///
/// The third card is for the adult who will be handed the tablet, and is
/// the only text on this screen written in a grown-up register.
///
/// [asReplay] is the same three cards opened deliberately from the settings.
/// It only ever goes back where it came from: the first-run version has to
/// build a navigator stack because there is none yet, and doing that from
/// the settings would replace the screen the parent was standing on.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.asReplay = false});

  final bool asReplay;

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

  void _finish() {
    if (widget.asReplay) {
      // Opened from the settings: give the parent their screen back and
      // touch nothing. The flag is already set, and re-reading the cards is
      // not a first run.
      Navigator.of(context).pop();
      return;
    }
    // The flag is set before the write starts, so nothing waits on the disk
    // to get out of here — a child who has tapped "let's paint" should not
    // be held at a welcome screen by a file write.
    unawaited(Settings.instance.markWelcomeSeen());
    final navigator = Navigator.of(context);
    // Home first, so there is something to go back *to*, then the pictures
    // on top of it — which is what the child sees.
    unawaited(navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    ));
    unawaited(navigator.push(
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
      duration: PixieMotion.enter,
      curve: PixieCurves.enter,
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
                          color: PixieTokens.quietInk),
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
              PageDots(count: _cardCount, index: _index),
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
        // A ceiling, because this is running text. Sideways on a tablet the
        // sentence ran the full window and became one very long line — the
        // hardest shape to read, and the third card is the one an adult is
        // actually meant to read.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopIn(
              from: 0.4,
              rotateFrom: -0.12,
              delay: PixieMotion.emojiDelay,
              child: Text(emoji, style: const TextStyle(fontSize: 88)),
            ),
            const SizedBox(height: PixieTokens.gapXl),
            StickerCard(
              color: Colors.white,
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
                  const SizedBox(height: PixieTokens.gapSmall),
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
      ),
    );
  }
}
