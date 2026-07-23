import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pixiepaint/stickers/sticker_store.dart';

class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

/// The kid's own stickers, cut out of their own paintings. Unlike an
/// artwork there is no older version to fall back to — a sticker written
/// halfway would sit in the album as an undecodable file forever.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  final png = Uint8List.fromList(List.filled(64, 7));

  setUp(() {
    root = Directory.systemTemp.createTempSync('pp_stickers');
    PathProviderPlatform.instance = _TempPathProvider(root.path);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Directory stickerDir() => Directory('${root.path}/stickers');

  test('a saved sticker lands complete and readable', () async {
    final file = await StickerStore.save(png);

    expect(file, isNotNull);
    expect(file!.readAsBytesSync(), png);
    expect((await StickerStore.list()).map((f) => f.path), contains(file.path));
  });

  test('the write leaves no temp file behind', () async {
    await StickerStore.save(png);

    expect(
      stickerDir().listSync().where((e) => e.path.endsWith('.tmp')),
      isEmpty,
      reason: 'a leftover .tmp would show up in the album as a broken entry',
    );
  });

  test('a failed write reports null instead of half a sticker', () async {
    // Make the whole sticker directory unwritable by replacing it with a
    // file — the same class of failure as a full disk.
    stickerDir().createSync(recursive: true);
    stickerDir().deleteSync();
    File(stickerDir().path).writeAsStringSync('not a directory');

    final file = await StickerStore.save(png);

    expect(file, isNull,
        reason: 'the capture screen needs to know, so it can say so');
  });

  test('listing is newest first', () async {
    final first = await StickerStore.save(png);
    // Same-millisecond timestamps would make the order arbitrary.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = await StickerStore.save(png);

    final listed = await StickerStore.list();
    expect(listed.first.path, second!.path);
    expect(listed.last.path, first!.path);
  });

  test('deleting removes only that sticker', () async {
    final keep = await StickerStore.save(png);
    final drop = await StickerStore.save(png);

    await StickerStore.delete(drop!);

    final listed = await StickerStore.list();
    expect(listed.map((f) => f.path), [keep!.path]);
  });

  test('deleting a sticker that is already gone is harmless', () async {
    final file = await StickerStore.save(png);
    await StickerStore.delete(file!);

    expect(() => StickerStore.delete(file), returnsNormally);
  });
}
