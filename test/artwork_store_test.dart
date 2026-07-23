import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pixiepaint/gallery/artwork_store.dart';
import 'package:pixiepaint/models/artwork.dart';

/// Redirects the documents dir into a temp folder so the store can be
/// exercised for real (same approach as backup_test.dart).
class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  final png = Uint8List.fromList([1, 2, 3]);

  setUp(() {
    root = Directory.systemTemp.createTempSync('pp_store');
    PathProviderPlatform.instance = _TempPathProvider(root.path);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<Artwork> save({
    required String id,
    String? pageId,
    String? traceId,
    String? sceneId,
    List<int>? cbnFilled,
    String? opsJson,
  }) =>
      ArtworkStore.save(
        id: id,
        pageId: pageId,
        traceId: traceId,
        sceneId: sceneId,
        cbnFilled: cbnFilled,
        width: 2048,
        height: 1536,
        paintPng: png,
        thumbPng: png,
        opsJson: opsJson,
      ).then((r) => r.artwork);

  Map<String, dynamic> meta(Artwork a) =>
      jsonDecode(File('${a.dirPath}/meta.json').readAsStringSync())
          as Map<String, dynamic>;

  test('name and favorite survive an autosave that does not know them',
      () async {
    final first = await save(id: 'a', pageId: 'cat');
    await ArtworkStore.updateMeta(
        first.copyWith(name: 'Mein Kater', favorite: true));

    // The canvas autosaves without any knowledge of the gallery metadata.
    final again = await save(id: 'a', pageId: 'cat');
    expect(again.name, 'Mein Kater');
    expect(again.favorite, isTrue);
  });

  test('mode fields are carried over when the caller passes nothing',
      () async {
    await save(
      id: 'b',
      pageId: 'cbn_fish',
      traceId: 'letter_A',
      sceneId: 'meadow',
      cbnFilled: [7, 9],
    );
    // A caller that forgets them must not erase a half-solved picture.
    final again = await save(id: 'b', pageId: null);
    expect(again.pageId, 'cbn_fish');
    expect(again.traceId, 'letter_A');
    expect(again.sceneId, 'meadow');
    expect(again.cbnFilled, [7, 9]);
  });

  test('an explicitly passed cbnFilled replaces the old one', () async {
    await save(id: 'c', pageId: 'cbn_fish', cbnFilled: [1]);
    final again = await save(id: 'c', pageId: 'cbn_fish', cbnFilled: [1, 2]);
    expect(again.cbnFilled, [1, 2]);
  });

  test('ops.json is written, then removed once the story is undone away',
      () async {
    final a = await save(id: 'd', pageId: null, opsJson: '{"v":1,"ops":[]}');
    expect(a.opsFile.existsSync(), isTrue);

    // Undoing back to a blank canvas passes null — the stale film must go,
    // otherwise the gallery offers a replay of strokes that no longer exist.
    await save(id: 'd', pageId: null);
    expect(a.opsFile.existsSync(), isFalse);
  });

  test('a corrupt meta.json is rebuilt instead of taking the save down',
      () async {
    final a = await save(id: 'e', pageId: 'dog');
    File('${a.dirPath}/meta.json').writeAsStringSync('{ not json');
    final again = await save(id: 'e', pageId: 'dog');
    expect(again.pageId, 'dog');
    expect(meta(again)['id'], 'e');
  });

  test('list() reads back what save() wrote', () async {
    await save(id: 'f', pageId: 'cat', traceId: 'letter_B');
    final all = await ArtworkStore.list();
    expect(all.map((a) => a.id), contains('f'));
    expect(all.firstWhere((a) => a.id == 'f').traceId, 'letter_B');
  });

  test('a save that dies mid-write leaves the previous version readable',
      () async {
    final a = await save(id: 'g', pageId: 'cat');
    final metaFile = File('${a.dirPath}/meta.json');
    final intact = metaFile.readAsStringSync();

    // What a crash or a full disk leaves behind with a plain writeAsString:
    // a truncated file. The atomic write makes this state unreachable —
    // meta.json is only ever replaced by a complete file via rename.
    final tmp = File('${metaFile.path}.tmp');
    tmp.writeAsStringSync(intact.substring(0, intact.length ~/ 2));
    expect(metaFile.readAsStringSync(), intact,
        reason: 'the half-written file must live beside meta.json, not in it');

    final all = await ArtworkStore.list();
    expect(all.map((a) => a.id), contains('g'));
  });

  test('save reports failure instead of committing a broken picture',
      () async {
    final a = await save(id: 'h', pageId: 'cat');
    final before = meta(a);

    // A directory where thumb.png belongs makes the write fail the same way
    // a full disk does: the bytes never land.
    a.thumbFile.deleteSync();
    Directory(a.thumbFile.path).createSync();

    final result = await ArtworkStore.save(
      id: 'h',
      pageId: 'cat',
      width: 2048,
      height: 1536,
      paintPng: png,
      thumbPng: png,
    );
    expect(result.ok, isFalse);
    // meta.json is the commit marker and was never reached, so the gallery
    // still finds the older, complete version.
    expect(meta(a), before);
    final all = await ArtworkStore.list();
    expect(all.map((x) => x.id), contains('h'));
  });
}
