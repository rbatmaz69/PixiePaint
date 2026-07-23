import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/backup.dart';

void main() {
  late Directory docs;
  late Directory tmp;

  setUp(() {
    docs = Directory.systemTemp.createTempSync('pp_docs');
    tmp = Directory.systemTemp.createTempSync('pp_tmp');
  });

  tearDown(() {
    if (docs.existsSync()) docs.deleteSync(recursive: true);
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Map<String, List<int>> unzip(String path) {
    final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    return {
      for (final f in archive.files)
        if (f.isFile) f.name: f.readBytes() ?? const []
    };
  }

  test('archive keeps the documents-relative layout a restore needs', () {
    final art = Directory('${docs.path}/artworks/abc-123')
      ..createSync(recursive: true);
    File('${art.path}/paint.png').writeAsBytesSync([1, 2, 3]);
    File('${art.path}/meta.json').writeAsStringSync('{"id":"abc-123"}');
    File('${docs.path}/progress.json').writeAsStringSync('{"tasksDone":2}');
    Directory('${docs.path}/stickers').createSync();
    File('${docs.path}/stickers/s1.png').writeAsBytesSync([9]);

    final out = '${tmp.path}/backup.zip';
    writeBackupZip(docs.path, out, '{"format":1}');

    final entries = unzip(out);
    expect(entries.keys, contains('artworks/abc-123/paint.png'));
    expect(entries.keys, contains('artworks/abc-123/meta.json'));
    expect(entries.keys, contains('progress.json'));
    expect(entries.keys, contains('stickers/s1.png'));
    expect(entries.keys, contains('manifest.json'));
    expect(entries['artworks/abc-123/paint.png'], [1, 2, 3]);
    expect(utf8.decode(entries['progress.json']!), '{"tasksDone":2}');
  });

  test('manifest carries the format version for future restores', () {
    final out = '${tmp.path}/backup.zip';
    final manifest = jsonEncode(
        {'format': kBackupFormat, 'exportedAt': '2026-07-21T10:00:00.000'});
    writeBackupZip(docs.path, out, manifest);

    final decoded = jsonDecode(utf8.decode(unzip(out)['manifest.json']!));
    expect(decoded['format'], kBackupFormat);
    expect(decoded['exportedAt'], isNotEmpty);
  });

  test('an empty documents dir still yields a valid archive', () {
    final out = '${tmp.path}/backup.zip';
    writeBackupZip(docs.path, out, '{"format":1}');
    expect(unzip(out).keys, ['manifest.json']);
  });

  test('device-specific settings.json is deliberately excluded', () {
    File('${docs.path}/settings.json').writeAsStringSync('{"musicOn":true}');
    final out = '${tmp.path}/backup.zip';
    writeBackupZip(docs.path, out, '{"format":1}');
    expect(unzip(out).keys, isNot(contains('settings.json')));
  });

  group('restore', () {
    late Directory target;

    setUp(() => target = Directory.systemTemp.createTempSync('pp_target'));
    tearDown(() {
      if (target.existsSync()) target.deleteSync(recursive: true);
    });

    /// Fills the source docs dir with two artworks, a sticker and progress.
    void seed() {
      for (final id in ['abc-123', 'def-456']) {
        final art = Directory('${docs.path}/artworks/$id')
          ..createSync(recursive: true);
        File('${art.path}/paint.png').writeAsBytesSync([1, 2, 3]);
        File('${art.path}/meta.json').writeAsStringSync('{"id":"$id"}');
      }
      Directory('${docs.path}/stickers').createSync();
      File('${docs.path}/stickers/s1.png').writeAsBytesSync([9]);
      File('${docs.path}/progress_main.json')
          .writeAsStringSync('{"tasksDone":2}');
    }

    String exportSeeded() {
      final out = '${tmp.path}/backup.zip';
      writeBackupZip(docs.path, out, jsonEncode({'format': kBackupFormat}));
      return out;
    }

    test('round-trips a whole gallery into an empty device', () {
      seed();
      final result = restoreBackupZip(exportSeeded(), target.path);

      expect(result.restored, 2);
      expect(result.skipped, 0);
      expect(
          File('${target.path}/artworks/abc-123/paint.png').readAsBytesSync(),
          [1, 2, 3]);
      expect(File('${target.path}/artworks/def-456/meta.json').existsSync(),
          isTrue);
      expect(File('${target.path}/stickers/s1.png').existsSync(), isTrue);
      expect(File('${target.path}/progress_main.json').readAsStringSync(),
          '{"tasksDone":2}');
    });

    test('parks the kid list beside the device\'s own instead of over it', () {
      seed();
      File('${docs.path}/profiles.json')
          .writeAsStringSync('{"profiles":[{"id":"from-backup"}]}');
      final zip = exportSeeded();
      File('${target.path}/profiles.json')
          .writeAsStringSync('{"profiles":[{"id":"on-device"}]}');

      restoreBackupZip(zip, target.path);

      // This device's own kid list is untouched; the backup's waits for
      // ProfileStore.mergeRestoredProfiles().
      expect(File('${target.path}/profiles.json').readAsStringSync(),
          contains('on-device'));
      expect(File('${target.path}/$kRestoredProfilesFile').readAsStringSync(),
          contains('from-backup'));
    });

    test('never overwrites a picture the device already has', () {
      seed();
      final zip = exportSeeded();
      // The same artwork, painted further on this device since the backup.
      final existing = Directory('${target.path}/artworks/abc-123')
        ..createSync(recursive: true);
      File('${existing.path}/paint.png').writeAsBytesSync([7, 7, 7]);

      final result = restoreBackupZip(zip, target.path);

      expect(result.restored, 1);
      expect(result.skipped, 1);
      expect(File('${existing.path}/paint.png').readAsBytesSync(), [7, 7, 7],
          reason: 'the newer local painting must survive a restore');
      expect(File('${target.path}/artworks/def-456/meta.json').existsSync(),
          isTrue);
    });

    test('a crafted entry cannot escape the documents dir', () {
      final out = '${tmp.path}/evil.zip';
      final encoder = ZipFileEncoder();
      encoder.create(out);
      encoder.addArchiveFile(ArchiveFile.string(
          'manifest.json', jsonEncode({'format': kBackupFormat})));
      encoder.addArchiveFile(
          ArchiveFile.string('../../evil.txt', 'pwned'));
      encoder.addArchiveFile(
          ArchiveFile.string('artworks/../../evil2.txt', 'pwned'));
      encoder.addArchiveFile(ArchiveFile.string('/etc/evil3.txt', 'pwned'));
      encoder.addArchiveFile(ArchiveFile.string('artworks/ok/meta.json', '{}'));
      encoder.closeSync();

      final result = restoreBackupZip(out, target.path);

      // The one legitimate entry lands; nothing else exists anywhere.
      expect(result.restored, 1);
      expect(File('${target.path}/artworks/ok/meta.json').existsSync(), isTrue);
      final outside = target.parent;
      expect(File('${outside.path}/evil.txt').existsSync(), isFalse);
      expect(File('${outside.path}/evil2.txt').existsSync(), isFalse);
      expect(File('/etc/evil3.txt').existsSync(), isFalse);
      expect(
        target
            .listSync(recursive: true)
            .map((e) => e.path.substring(target.path.length + 1)),
        everyElement(isNot(contains('evil'))),
      );
    });

    test('refuses a ZIP that is not one of ours', () {
      final out = '${tmp.path}/random.zip';
      final encoder = ZipFileEncoder();
      encoder.create(out);
      encoder.addArchiveFile(ArchiveFile.string('holiday.jpg', 'not a backup'));
      encoder.closeSync();

      expect(
        () => restoreBackupZip(out, target.path),
        throwsA(isA<BackupRejected>().having(
            (e) => e.reason, 'reason', BackupRejection.notABackup)),
      );
    });

    test('refuses a backup from a newer PixiePaint', () {
      final out = '${tmp.path}/future.zip';
      final encoder = ZipFileEncoder();
      encoder.create(out);
      encoder.addArchiveFile(ArchiveFile.string(
          'manifest.json', jsonEncode({'format': kBackupFormat + 1})));
      encoder.closeSync();

      expect(
        () => restoreBackupZip(out, target.path),
        throwsA(isA<BackupRejected>()
            .having((e) => e.reason, 'reason', BackupRejection.tooNew)),
      );
    });

    test('an artwork only becomes visible once meta.json lands', () {
      seed();
      final zip = exportSeeded();
      restoreBackupZip(zip, target.path);

      // meta.json is written last, so no leftover .tmp files may remain and
      // every restored directory must be complete.
      for (final dir
          in Directory('${target.path}/artworks').listSync().whereType<Directory>()) {
        expect(File('${dir.path}/meta.json').existsSync(), isTrue,
            reason: 'a directory without meta.json is invisible to the gallery');
        expect(
          dir.listSync().where((e) => e.path.endsWith('.tmp')),
          isEmpty,
          reason: 'the atomic write must clean up after itself',
        );
      }
    });

    test('an unwritable target is skipped instead of half-written', () {
      seed();
      final zip = exportSeeded();
      // A directory where paint.png belongs: the write cannot succeed.
      Directory('${target.path}/artworks/abc-123/paint.png')
          .createSync(recursive: true);

      restoreBackupZip(zip, target.path);

      // abc-123 already existed as a directory, so it is skipped entirely;
      // the other artwork still comes through, and nothing is left half done.
      expect(File('${target.path}/artworks/def-456/meta.json').existsSync(),
          isTrue);
      expect(
        Directory(target.path)
            .listSync(recursive: true)
            .where((e) => e.path.endsWith('.tmp')),
        isEmpty,
      );
    });

    test('refuses a file that is not a ZIP at all', () {
      final out = '${tmp.path}/photo.png';
      File(out).writeAsBytesSync(List.filled(64, 0x42));

      expect(() => restoreBackupZip(out, target.path),
          throwsA(isA<BackupRejected>()));
    });
  });
}
