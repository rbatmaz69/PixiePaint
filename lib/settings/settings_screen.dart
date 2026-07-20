import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/soft_card.dart';
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
      {bool? stylusOnly, bool? deleteNeedsGate, bool? soundsOn}) async {
    await Settings.instance.update(
        stylusOnly: stylusOnly,
        deleteNeedsGate: deleteNeedsGate,
        soundsOn: soundsOn);
    Sfx.instance.tick();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Settings.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        backgroundColor: Colors.transparent,
      ),
      body: BlobBackground(
        gradient: PixieGradients.homeBg,
        builder: (context, _) => ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _staggered(
                0,
                _Section(
                  title: context.l10n.settingsSectionSafety,
                  emoji: '🔒',
                  children: [
                    SwitchListTile(
                      title: Text(context.l10n.stylusOnlyTitle),
                      subtitle: Text(context.l10n.stylusOnlySubtitle),
                      value: settings.stylusOnly,
                      onChanged: (v) => _update(stylusOnly: v),
                    ),
                    SwitchListTile(
                      title: Text(context.l10n.deleteGateTitle),
                      subtitle: Text(context.l10n.deleteGateSubtitle),
                      value: settings.deleteNeedsGate,
                      onChanged: (v) => _update(deleteNeedsGate: v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _staggered(
                1,
                _Section(
                  title: context.l10n.settingsSectionFun,
                  emoji: '🎵',
                  children: [
                    SwitchListTile(
                      title: Text(context.l10n.soundsTitle),
                      subtitle: Text(context.l10n.soundsSubtitle),
                      value: settings.soundsOn,
                      onChanged: (v) => _update(soundsOn: v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _staggered(
                2,
                _Section(
                  title: context.l10n.settingsSectionAbout,
                  emoji: 'ℹ️',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.star_outline_rounded),
                      title: Text(context.l10n.rateApp),
                      subtitle: Text(context.l10n.rateAppSubtitle),
                      onTap: openStoreListing,
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(context.l10n.aboutTitle),
                      subtitle: Text(context.l10n.aboutBody),
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

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.emoji, required this.children});

  final String title;
  final String emoji;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Text(
            '$emoji  $title',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        SoftCard(
          color: Colors.white,
          radius: 24,
          shadowColor: Colors.black38,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }
}
