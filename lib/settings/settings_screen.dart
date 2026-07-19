import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../util/review.dart';
import '../util/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Settings.instance;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
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
            SwitchListTile(
              title: Text(context.l10n.soundsTitle),
              subtitle: Text(context.l10n.soundsSubtitle),
              value: settings.soundsOn,
              onChanged: (v) => settings.update(soundsOn: v),
            ),
            const SizedBox(height: 24),
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
    );
  }
}
