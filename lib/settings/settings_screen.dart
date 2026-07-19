import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/soft_card.dart';
import '../util/review.dart';
import '../util/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Settings.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: PixieGradients.homeBg),
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: context.l10n.settingsSectionSafety,
                emoji: '🔒',
                children: [
                  SwitchListTile(
                    title: Text(context.l10n.stylusOnlyTitle),
                    subtitle: Text(context.l10n.stylusOnlySubtitle),
                    value: settings.stylusOnly,
                    onChanged: (v) => settings.update(stylusOnly: v),
                  ),
                  SwitchListTile(
                    title: Text(context.l10n.deleteGateTitle),
                    subtitle: Text(context.l10n.deleteGateSubtitle),
                    value: settings.deleteNeedsGate,
                    onChanged: (v) => settings.update(deleteNeedsGate: v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: context.l10n.settingsSectionFun,
                emoji: '🎵',
                children: [
                  SwitchListTile(
                    title: Text(context.l10n.soundsTitle),
                    subtitle: Text(context.l10n.soundsSubtitle),
                    value: settings.soundsOn,
                    onChanged: (v) => settings.update(soundsOn: v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
