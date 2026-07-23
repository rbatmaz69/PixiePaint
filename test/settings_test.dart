import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/json_store.dart';
import 'package:pixiepaint/util/settings.dart';

/// A parent's choices have to outlive the app being closed. These tests
/// drive the store directly — the widget tests cover the switches, this
/// covers what reaches the disk.
void main() {
  late Directory dir;
  late File file;
  final settings = Settings.instance;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pp_settings');
    file = File('${dir.path}/settings.json');
    settings.resetForTest();
  });

  tearDown(() {
    settings.resetForTest();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> load() => settings.loadFrom(JsonStore(file));

  Map<String, dynamic> onDisk() =>
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  test('a fresh install starts with the safe defaults', () async {
    await load();
    expect(settings.stylusOnly, isFalse);
    expect(settings.soundsOn, isTrue);
    // Music stays off until a parent turns it on — nothing should start
    // making noise on first launch.
    expect(settings.musicOn, isFalse);
    expect(settings.leftHanded, isFalse);
  });

  test('every toggle survives a restart', () async {
    await load();
    await settings.update(
      stylusOnly: true,
      deleteNeedsGate: true,
      soundsOn: false,
      musicOn: true,
      musicTrack: 1,
      leftHanded: true,
    );
    await settings.flush();

    // A second store over the same file is what the next app start sees.
    await settings.loadFrom(JsonStore(file));
    expect(settings.stylusOnly, isTrue);
    expect(settings.deleteNeedsGate, isTrue);
    expect(settings.soundsOn, isFalse);
    expect(settings.musicOn, isTrue);
    expect(settings.musicTrack, 1);
    expect(settings.leftHanded, isTrue);
  });

  test('an update reaches the file, not just memory', () async {
    await load();
    await settings.update(leftHanded: true);
    await settings.flush();

    expect(onDisk()['leftHanded'], isTrue);
  });

  test('a settings file from an older version fills in the new fields',
      () async {
    file.writeAsStringSync('{"soundsOn": false}');
    await load();

    expect(settings.soundsOn, isFalse);
    expect(settings.leftHanded, isFalse);
    expect(settings.musicTrack, 0);
    expect(settings.recentColors, isEmpty);
  });

  test('a corrupt settings file falls back to defaults instead of crashing',
      () async {
    file.writeAsStringSync('{ not json');
    await load();

    expect(settings.soundsOn, isTrue);
    // JsonStore preserves the unreadable file rather than overwriting it.
    expect(File('${file.path}.corrupt.json').existsSync(), isTrue);
  });

  test('recent colors are remembered across restarts', () async {
    await load();
    await settings.registerRecentColor(const Color(0xFFE53935));
    await settings.registerRecentColor(const Color(0xFF1E88E5));
    await settings.flush();

    await settings.loadFrom(JsonStore(file));
    expect(settings.recentColors.first, const Color(0xFF1E88E5).toARGB32());
    expect(settings.recentColors, hasLength(2));
  });
}
