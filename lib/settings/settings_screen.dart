import 'package:flutter/material.dart';

import '../util/settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Settings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Nur mit Stift malen'),
              subtitle: const Text(
                  'Fingerberührungen malen nicht – praktisch, damit die '
                  'Handfläche keine Striche macht.'),
              value: settings.stylusOnly,
              onChanged: (v) => settings.update(stylusOnly: v),
            ),
            SwitchListTile(
              title: const Text('Löschen nur für Eltern'),
              subtitle: const Text(
                  'Bilder können nur nach der Eltern-Frage gelöscht werden.'),
              value: settings.deleteNeedsGate,
              onChanged: (v) => settings.update(deleteNeedsGate: v),
            ),
            const SizedBox(height: 24),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('PixiePaint'),
              subtitle: Text(
                  'Eine Malbuch-App für Kinder. Keine Werbung, keine '
                  'Datensammlung – alle Bilder bleiben auf diesem Gerät.'),
            ),
          ],
        ),
      ),
    );
  }
}
