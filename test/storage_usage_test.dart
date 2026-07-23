import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/storage_usage.dart';

void main() {
  late Directory docs;

  setUp(() => docs = Directory.systemTemp.createTempSync('pp_usage'));
  tearDown(() {
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  void artwork(String id, {int paint = 100, int thumb = 20}) {
    final dir = Directory('${docs.path}/artworks/$id')..createSync(recursive: true);
    File('${dir.path}/paint.png').writeAsBytesSync(List.filled(paint, 0));
    File('${dir.path}/thumb.png').writeAsBytesSync(List.filled(thumb, 0));
  }

  test('counts every file inside every artwork directory', () {
    artwork('a');
    artwork('b', paint: 300);

    final usage = measureStorageUsage(docs.path);
    expect(usage.artworkCount, 2);
    expect(usage.artworkBytes, 100 + 20 + 300 + 20);
  });

  test('stickers are reported apart from the pictures', () {
    artwork('a');
    Directory('${docs.path}/stickers').createSync();
    File('${docs.path}/stickers/s1.png').writeAsBytesSync(List.filled(50, 0));

    final usage = measureStorageUsage(docs.path);
    expect(usage.stickerBytes, 50);
    expect(usage.artworkBytes, 120);
    expect(usage.totalBytes, 170);
  });

  test('a fresh install reports nothing rather than failing', () {
    final usage = measureStorageUsage(docs.path);
    expect(usage.artworkCount, 0);
    expect(usage.totalBytes, 0);
  });

  test('settings and progress files are not counted as gallery weight', () {
    File('${docs.path}/settings.json').writeAsStringSync('{"musicOn":true}');
    File('${docs.path}/progress.json').writeAsStringSync('{"tasksDone":9}');

    expect(measureStorageUsage(docs.path).totalBytes, 0);
  });

  group('formatBytes', () {
    test('climbs units at the right thresholds', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
    });

    test('a full gallery reads as megabytes, not a wall of digits', () {
      expect(formatBytes(47 * 1024 * 1024 + 512 * 1024), '47.5 MB');
    });
  });
}
