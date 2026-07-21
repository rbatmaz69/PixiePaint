import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/music.dart';
import '../util/review.dart';
import '../util/settings.dart';
import '../util/sfx.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Fade + rise on the shared entrance controller, slot-staggered.
  Widget _staggered(int slot, Widget child) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(0.10 * slot, 0.10 * slot + 0.55,
          curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  /// Persist and tick — after the update, so switching sounds OFF is
  /// correctly silent and switching ON ticks.
  Future<void> _update(
      {bool? stylusOnly,
      bool? deleteNeedsGate,
      bool? soundsOn,
      bool? musicOn,
      bool? leftHanded}) async {
    await Settings.instance.update(
        stylusOnly: stylusOnly,
        deleteNeedsGate: deleteNeedsGate,
        soundsOn: soundsOn,
        musicOn: musicOn,
        leftHanded: leftHanded);
    if (musicOn != null) await Music.instance.setOn(musicOn);
    Sfx.instance.tick();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Settings.instance;
    return Scaffold(
      body: BlobBackground(
        gradient: PixieGradients.homeBg,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              PixieHeader(
                emoji: '⚙️',
                title: context.l10n.settingsTitle,
                accent: PixiePalette.grape,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _staggered(
                        0,
                        _Section(
                          title: context.l10n.settingsSectionSafety,
                          emoji: '🔒',
                          accent: PixiePalette.sky,
                          tiltIndex: 0,
                          children: [
                            _KidRow(
                              emoji: '✍️',
                              tint: PixiePalette.skyLight,
                              title: context.l10n.stylusOnlyTitle,
                              subtitle: context.l10n.stylusOnlySubtitle,
                              value: settings.stylusOnly,
                              onChanged: (v) => _update(stylusOnly: v),
                            ),
                            _KidRow(
                              emoji: '🗑️',
                              tint: PixiePalette.skyLight,
                              title: context.l10n.deleteGateTitle,
                              subtitle: context.l10n.deleteGateSubtitle,
                              value: settings.deleteNeedsGate,
                              onChanged: (v) => _update(deleteNeedsGate: v),
                            ),
                            _KidRow(
                              emoji: '✋',
                              tint: PixiePalette.skyLight,
                              title: context.l10n.leftHandedTitle,
                              subtitle: context.l10n.leftHandedSubtitle,
                              value: settings.leftHanded,
                              onChanged: (v) => _update(leftHanded: v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _staggered(
                        1,
                        _Section(
                          title: context.l10n.settingsSectionFun,
                          emoji: '🎵',
                          accent: PixiePalette.bubblegum,
                          tiltIndex: 3,
                          children: [
                            _KidRow(
                              emoji: '🔊',
                              tint: PixiePalette.bubblegumLight,
                              title: context.l10n.soundsTitle,
                              subtitle: context.l10n.soundsSubtitle,
                              value: settings.soundsOn,
                              onChanged: (v) => _update(soundsOn: v),
                            ),
                            _KidRow(
                              emoji: '🎶',
                              tint: PixiePalette.bubblegumLight,
                              title: context.l10n.musicTitle,
                              subtitle: context.l10n.musicSubtitle,
                              value: settings.musicOn,
                              onChanged: (v) => _update(musicOn: v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _staggered(
                        2,
                        _Section(
                          title: context.l10n.settingsSectionAbout,
                          emoji: 'ℹ️',
                          accent: PixiePalette.grape,
                          tiltIndex: 1,
                          children: [
                            _KidRow(
                              emoji: '⭐',
                              tint: PixiePalette.grapeLight,
                              title: context.l10n.rateApp,
                              subtitle: context.l10n.rateAppSubtitle,
                              onTap: openStoreListing,
                            ),
                            _KidRow(
                              emoji: '🎨',
                              tint: PixiePalette.grapeLight,
                              title: context.l10n.aboutTitle,
                              subtitle: context.l10n.aboutBody,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emoji,
    required this.accent,
    required this.tiltIndex,
    required this.children,
  });

  final String title;
  final String emoji;
  final Color accent;
  final int tiltIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Row(
            children: [
              StickerEmoji(emoji, size: 18, shadowColor: accent),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: PixiePalette.ink),
              ),
            ],
          ),
        ),
        StickerCard(
          color: Colors.white,
          radius: 24,
          shadowColor: accent,
          tiltIndex: tiltIndex,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Kid-styled settings row: emoji on a tinted squircle, Fredoka texts and
/// either a chunky switch or a tap action — replaces stock ListTiles.
class _KidRow extends StatelessWidget {
  const _KidRow({
    required this.emoji,
    required this.tint,
    required this.title,
    required this.subtitle,
    this.value,
    this.onChanged,
    this.onTap,
  });

  final String emoji;
  final Color tint;
  final String title;
  final String subtitle;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (onChanged != null) ...[
            const SizedBox(width: 8),
            Transform.scale(
              scale: 1.15,
              child: Switch(value: value ?? false, onChanged: onChanged),
            ),
          ],
        ],
      ),
    );
    if (onTap != null) {
      return Bouncy(onTap: onTap, minSize: 0, child: row);
    }
    return row;
  }
}
