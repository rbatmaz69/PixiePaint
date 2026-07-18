import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// App settings, persisted as a small JSON file in the documents dir.
class Settings extends ChangeNotifier {
  Settings._();
  static final Settings instance = Settings._();

  bool stylusOnly = false;
  bool deleteNeedsGate = false;

  File? _file;

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/settings.json');
      if (await _file!.exists()) {
        final json = jsonDecode(await _file!.readAsString());
        stylusOnly = json['stylusOnly'] as bool? ?? false;
        deleteNeedsGate = json['deleteNeedsGate'] as bool? ?? false;
      }
    } catch (_) {
      // defaults are fine
    }
  }

  Future<void> update({bool? stylusOnly, bool? deleteNeedsGate}) async {
    if (stylusOnly != null) this.stylusOnly = stylusOnly;
    if (deleteNeedsGate != null) this.deleteNeedsGate = deleteNeedsGate;
    notifyListeners();
    try {
      await _file?.writeAsString(jsonEncode({
        'stylusOnly': this.stylusOnly,
        'deleteNeedsGate': this.deleteNeedsGate,
      }));
    } catch (_) {}
  }
}
