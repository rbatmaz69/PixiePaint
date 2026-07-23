import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/canvas/save_session.dart';
import 'package:pixiepaint/util/profiles.dart';
import 'package:pixiepaint/util/progress.dart';
import 'package:pixiepaint/util/settings.dart';

class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

/// The save pipeline, now that it lives outside the widget. What matters
/// here is the behaviour a child depends on: never lose a picture, never
/// create junk, and never let two saves collide.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late CanvasController controller;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('pp_save');
    PathProviderPlatform.instance = _TempPathProvider(root.path);
    Settings.instance.resetForTest();
    ProfileStore.instance.resetForTest();
    Progress.instance.resetForTest();
    await ProfileStore.instance.load();
    controller = CanvasController(canvasWidth: 64, canvasHeight: 48);
  });

  tearDown(() async {
    controller.dispose();
    await Progress.instance.flush();
    ProfileStore.instance.resetForTest();
    Progress.instance.resetForTest();
    Settings.instance.resetForTest();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  ArtworkSaveSession session({
    String id = 'artwork-1',
    bool resumed = false,
    List<int> cbn = const [],
  }) =>
      ArtworkSaveSession(
        controller: controller,
        artworkId: id,
        width: 64,
        height: 48,
        hasPhoto: false,
        hasPhotoLineArt: false,
        cbnFilled: () => cbn,
        resumed: resumed,
      );

  /// One committed stroke, via the same pointer path the screen uses.
  void paintSomething({int pointer = 1}) {
    controller.pointerDown(PointerDownEvent(
        pointer: pointer, kind: PointerDeviceKind.touch, position: const Offset(8, 8)));
    controller.pointerMove(PointerMoveEvent(
        pointer: pointer, kind: PointerDeviceKind.touch, position: const Offset(30, 30)));
    controller.pointerUp(PointerUpEvent(
        pointer: pointer, kind: PointerDeviceKind.touch, position: const Offset(30, 30)));
  }

  Directory dirOf(String id) => Directory('${root.path}/artworks/$id');

  test('an untouched canvas does not become an artwork', () async {
    await session().save();

    expect(dirOf('artwork-1').existsSync(), isFalse,
        reason: 'opening a picture and leaving must not litter the gallery');
  });

  test('a painted canvas is written with all its parts', () async {
    paintSomething();
    final s = session();
    await s.save();

    final dir = dirOf('artwork-1');
    expect(File('${dir.path}/paint.png').existsSync(), isTrue);
    expect(File('${dir.path}/thumb.png').existsSync(), isTrue);
    expect(File('${dir.path}/meta.json').existsSync(), isTrue);
    expect(s.everSaved, isTrue);
    expect(s.saveFailed, isFalse);
    expect(controller.dirty, isFalse, reason: 'a saved picture is clean');
  });

  test('saving twice without changes does no work the second time', () async {
    paintSomething();
    final s = session();
    await s.save();
    final firstWrite =
        File('${dirOf('artwork-1').path}/meta.json').lastModifiedSync();

    await s.save();

    expect(File('${dirOf('artwork-1').path}/meta.json').lastModifiedSync(),
        firstWrite,
        reason: 'the autosave fires every 30 s — it must be free when idle');
  });

  test('concurrent saves are serialized, not interleaved', () async {
    paintSomething();
    final s = session();

    // The three real callers firing at once: timer, lifecycle, leaving.
    await Future.wait([s.save(), s.save(), s.save()]);

    final meta = jsonDecode(
        File('${dirOf('artwork-1').path}/meta.json').readAsStringSync());
    expect(meta['id'], 'artwork-1',
        reason: 'overlapping writes would leave meta.json unparseable');
  });

  test('a stroke drawn during the save keeps the canvas dirty', () async {
    paintSomething();
    final s = session();

    final saving = s.save();
    // Encoding is async — this lands in the middle of it.
    paintSomething(pointer: 2);
    await saving;

    expect(controller.dirty, isTrue,
        reason: 'the later stroke was not in the file, so it is unsaved');
  });

  test('a finished picture counts towards the sticker rewards', () async {
    paintSomething();
    await session().save();

    expect(Progress.instance.completedArtworkIds, contains('artwork-1'));
  });

  test('a resumed artwork saves without repainting first', () async {
    // Resumed means: already on disk, canvas not dirty yet.
    paintSomething();
    await session().save();
    controller.dirty = false;

    final resumedSession = session(resumed: true);
    await resumedSession.save();

    expect(resumedSession.everSaved, isTrue);
    expect(dirOf('artwork-1').existsSync(), isTrue);
  });

  test('a failed write is remembered and the picture stays dirty', () async {
    paintSomething();
    // A directory where thumb.png belongs makes the write fail the way a
    // full disk does.
    final dir = dirOf('artwork-1')..createSync(recursive: true);
    Directory('${dir.path}/thumb.png').createSync();

    final s = session();
    await s.save();

    expect(s.saveFailed, isTrue);
    expect(s.everSaved, isFalse);
    expect(controller.dirty, isTrue,
        reason: 'staying dirty is what makes the next autosave retry');
  });

  test('a retry after the obstacle is gone succeeds', () async {
    paintSomething();
    final dir = dirOf('artwork-1')..createSync(recursive: true);
    final blocker = Directory('${dir.path}/thumb.png')..createSync();

    final s = session();
    await s.save();
    expect(s.saveFailed, isTrue);

    blocker.deleteSync();
    await s.save();

    expect(s.saveFailed, isFalse);
    expect(s.everSaved, isTrue);
  });

  test('color-by-number progress is read at save time, not at construction',
      () async {
    final filled = <int>[];
    final s = ArtworkSaveSession(
      controller: controller,
      artworkId: 'cbn-1',
      width: 64,
      height: 48,
      hasPhoto: false,
      hasPhotoLineArt: false,
      pageId: 'cbn_fish',
      cbnFilled: () => filled,
    );

    paintSomething();
    filled.addAll([3, 7]);
    await s.save();

    final meta = jsonDecode(
        File('${dirOf('cbn-1').path}/meta.json').readAsStringSync());
    expect(meta['cbnFilled'], [3, 7],
        reason: 'regions solved after the session was built must be included');
  });
}
