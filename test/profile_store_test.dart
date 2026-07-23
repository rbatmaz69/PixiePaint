import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/json_store.dart';
import 'package:pixiepaint/util/profiles.dart';

void main() {
  late Directory dir;
  final store = ProfileStore.instance;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pp_profiles');
    store.resetForTest();
  });

  tearDown(() {
    store.resetForTest();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  JsonStore file() => JsonStore(File('${dir.path}/profiles.json'));

  group('migration', () {
    test('a fresh install creates one primary profile', () async {
      await store.loadFrom(file(), dir);
      expect(store.profiles, hasLength(1));
      expect(store.active.id, store.primary.id);
      expect(store.primary.emoji, '🦄');
    });

    test('legacy progress.json is copied to the primary profile file',
        () async {
      File('${dir.path}/progress.json')
          .writeAsStringSync('{"tasksDone": 4}');
      await store.loadFrom(file(), dir);
      final copied =
          File('${dir.path}/progress_${store.primary.id}.json');
      expect(copied.existsSync(), isTrue);
      expect(jsonDecode(copied.readAsStringSync())['tasksDone'], 4);
      // The original stays as a backup.
      expect(File('${dir.path}/progress.json').existsSync(), isTrue);
    });

    test('migration only runs once — a second load keeps the same id',
        () async {
      await store.loadFrom(file(), dir);
      final id = store.primary.id;
      await store.flush();

      final reopened = ProfileStore.instance..resetForTest();
      await reopened.loadFrom(JsonStore(File('${dir.path}/profiles.json')), dir);
      expect(reopened.primary.id, id);
      expect(reopened.profiles, hasLength(1));
    });
  });

  group('ownership fallback', () {
    test('null-owner artworks belong to the primary, not to others',
        () async {
      await store.loadFrom(file(), dir);
      final primaryId = store.primary.id;
      final other = await store.addProfile(name: 'Mia', emoji: '🐱');
      expect(store.ownsArtwork(null, primaryId), isTrue);
      expect(store.ownsArtwork(null, other.id), isFalse);
      expect(store.ownsArtwork(other.id, other.id), isTrue);
      expect(store.ownsArtwork(primaryId, other.id), isFalse);
    });
  });

  group('managing profiles', () {
    test('adding is capped at the maximum', () async {
      await store.loadFrom(file(), dir);
      for (var i = 0; store.canAddMore; i++) {
        await store.addProfile(name: 'Kid$i', emoji: '🐶');
      }
      expect(store.profiles, hasLength(ProfileStore.maxProfiles));
      expect(store.canAddMore, isFalse);
    });

    test('adding a profile makes it active', () async {
      await store.loadFrom(file(), dir);
      final added = await store.addProfile(name: 'Bo', emoji: '🦊');
      expect(store.active.id, added.id);
    });

    test('switching changes the active profile', () async {
      await store.loadFrom(file(), dir);
      final primaryId = store.primary.id;
      final other = await store.addProfile(name: 'Lena', emoji: '🐰');
      store.switchTo(primaryId);
      expect(store.active.id, primaryId);
      store.switchTo(other.id);
      expect(store.active.id, other.id);
    });

    test('renaming updates name and face', () async {
      await store.loadFrom(file(), dir);
      final p = await store.addProfile(name: 'X', emoji: '🐶');
      await store.updateProfile(p.id, name: 'Emma', emoji: '🐼');
      final updated = store.profiles.firstWhere((e) => e.id == p.id);
      expect(updated.name, 'Emma');
      expect(updated.emoji, '🐼');
    });

    test('the primary profile can never be removed', () async {
      await store.loadFrom(file(), dir);
      await store.removeProfile(store.primary.id);
      expect(store.profiles, hasLength(1));
    });

    test('removing the active profile falls back to the primary and deletes '
        'its progress file', () async {
      await store.loadFrom(file(), dir);
      final other = await store.addProfile(name: 'Tom', emoji: '🐵');
      final progressFile =
          File('${dir.path}/progress_${other.id}.json')
            ..writeAsStringSync('{"tasksDone": 2}');
      expect(store.active.id, other.id);

      await store.removeProfile(other.id);
      expect(store.active.id, store.primary.id);
      expect(store.profiles, hasLength(1));
      expect(progressFile.existsSync(), isFalse);
    });
  });

  group('persistence', () {
    test('profiles and the active id survive a reload', () async {
      await store.loadFrom(file(), dir);
      await store.addProfile(name: 'Ada', emoji: '🐧');
      final activeId = store.active.id;
      await store.flush();

      final reopened = ProfileStore.instance..resetForTest();
      await reopened.loadFrom(JsonStore(File('${dir.path}/profiles.json')), dir);
      expect(reopened.profiles, hasLength(2));
      expect(reopened.active.id, activeId);
      expect(reopened.profiles.map((p) => p.name), contains('Ada'));
    });
  });
}
