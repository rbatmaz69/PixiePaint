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
}
