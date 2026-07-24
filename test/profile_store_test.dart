import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/backup.dart';
import 'package:pixiepaint/util/json_store.dart';
import 'package:pixiepaint/util/profiles.dart';

void main() {
  late Directory dir;
  final store = ProfileStore.instance;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pp_profiles');
    store.resetForTest();
  });

  tearDown(() async {
    // switchTo() persists without awaiting, so drain the queue before the
    // directory goes — otherwise the delete races JsonStore's .tmp file.
    await store.flush();
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

    test('the simple toolbar is a per-kid setting that survives a restart',
        () async {
      await store.loadFrom(file(), dir);
      // Default: everyone gets the full box of tools.
      expect(store.primary.simpleTools, isFalse);

      final little = await store.addProfile(
          name: 'Nils', emoji: '🐧', simpleTools: true);
      await store.updateProfile(store.primary.id, name: 'Emma');
      await store.flush();

      final reopened = ProfileStore.instance..resetForTest();
      await reopened.loadFrom(
          JsonStore(File('${dir.path}/profiles.json')), dir);
      expect(
          reopened.profiles.firstWhere((p) => p.id == little.id).simpleTools,
          isTrue);
      expect(reopened.primary.simpleTools, isFalse,
          reason: 'the big sibling keeps all fourteen tools');
    });

    test('the switch can be turned back off as a child grows into it',
        () async {
      await store.loadFrom(file(), dir);
      final p =
          await store.addProfile(name: 'Nils', emoji: '🐧', simpleTools: true);
      await store.updateProfile(p.id, simpleTools: false);
      expect(store.profiles.firstWhere((e) => e.id == p.id).simpleTools,
          isFalse);
      // ...and renaming must not silently reset it.
      await store.updateProfile(p.id, simpleTools: true);
      await store.updateProfile(p.id, name: 'Nils B.');
      final updated = store.profiles.firstWhere((e) => e.id == p.id);
      expect(updated.name, 'Nils B.');
      expect(updated.simpleTools, isTrue);
    });

    test('a profiles.json from before v8.1 reads as the full toolbar',
        () async {
      File('${dir.path}/profiles.json').writeAsStringSync(jsonEncode({
        'profiles': [
          {'id': 'kid-1', 'name': 'Mia', 'emoji': '🐸'},
        ],
        'activeProfileId': 'kid-1',
      }));
      await store.loadFrom(file(), dir);
      expect(store.primary.simpleTools, isFalse);
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

  group('restored profiles', () {
    /// What restoreBackupZip leaves behind: the backup's kid list, parked
    /// beside the device's own.
    void parkRestored(List<Map<String, String>> kids) {
      File('${dir.path}/$kRestoredProfilesFile')
          .writeAsStringSync(jsonEncode({'profiles': kids}));
    }

    test('kids from the backup are added so their pictures have an owner',
        () async {
      await store.loadFrom(file(), dir);
      parkRestored([
        {'id': 'backup-kid-1', 'name': 'Mia', 'emoji': '🐸'},
        {'id': 'backup-kid-2', 'name': 'Tom', 'emoji': '🦖'},
      ]);

      expect(await store.mergeRestoredProfiles(), 2);
      expect(store.profiles.map((p) => p.id),
          containsAll(['backup-kid-1', 'backup-kid-2']));
      // Restored artworks are stamped with these ids — without the kids,
      // ownsArtwork would hide every one of them.
      expect(store.ownsArtwork('backup-kid-1', 'backup-kid-1'), isTrue);
    });

    test('a restored kid brings their simple toolbar along', () async {
      await store.loadFrom(file(), dir);
      File('${dir.path}/$kRestoredProfilesFile').writeAsStringSync(jsonEncode({
        'profiles': [
          {
            'id': 'backup-kid-1',
            'name': 'Nils',
            'emoji': '🐧',
            'simpleTools': true,
          },
        ],
      }));

      expect(await store.mergeRestoredProfiles(), 1);
      expect(
          store.profiles.firstWhere((p) => p.id == 'backup-kid-1').simpleTools,
          isTrue,
          reason: 'a restore that hands a toddler fourteen tools is a bug');
    });

    test('a kid this device already knows keeps its own name', () async {
      await store.loadFrom(file(), dir);
      final mine = store.primary.id;
      await store.updateProfile(mine, name: 'Lena');
      parkRestored([
        {'id': mine, 'name': 'Old Name', 'emoji': '👻'},
      ]);

      expect(await store.mergeRestoredProfiles(), 0);
      expect(store.profiles, hasLength(1));
      expect(store.primary.name, 'Lena');
    });

    test('the side file is consumed, so a second merge is a no-op', () async {
      await store.loadFrom(file(), dir);
      parkRestored([
        {'id': 'backup-kid-1', 'name': 'Mia', 'emoji': '🐸'},
      ]);

      expect(await store.mergeRestoredProfiles(), 1);
      expect(File('${dir.path}/$kRestoredProfilesFile').existsSync(), isFalse);
      expect(await store.mergeRestoredProfiles(), 0);
      expect(store.profiles, hasLength(2));
    });

    test('the four-kid cap still holds', () async {
      await store.loadFrom(file(), dir);
      parkRestored([
        for (var i = 0; i < 6; i++)
          {'id': 'backup-kid-$i', 'name': 'Kid $i', 'emoji': '🐸'},
      ]);

      await store.mergeRestoredProfiles();
      expect(store.profiles, hasLength(ProfileStore.maxProfiles));
    });

    test('a damaged side file costs the kid list, not the restore', () async {
      await store.loadFrom(file(), dir);
      File('${dir.path}/$kRestoredProfilesFile').writeAsStringSync('{ not json');

      expect(await store.mergeRestoredProfiles(), 0);
      expect(store.profiles, hasLength(1));
      expect(File('${dir.path}/$kRestoredProfilesFile').existsSync(), isFalse);
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
