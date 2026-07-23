import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pixiepaint/canvas/canvas_controller.dart';
import 'package:pixiepaint/canvas/two_painter_save.dart';
import 'package:pixiepaint/util/profiles.dart';
import 'package:pixiepaint/util/progress.dart';
import 'package:pixiepaint/util/settings.dart';

class _TempPathProvider extends PathProviderPlatform {
  _TempPathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

/// Two kids share one tablet here. Until v7.2 the joint picture was written
/// only when someone deliberately left the screen — no autosave, nothing on
/// the way to the background — and the artwork id was minted inside that
/// call. The second half is the subtle one: an autosave built on the old
/// code would have produced a brand-new gallery entry every thirty seconds.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late CanvasController left;
  late CanvasController right;

  const w = 64, h = 96;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('pp_two');
    PathProviderPlatform.instance = _TempPathProvider(root.path);
    Settings.instance.resetForTest();
    ProfileStore.instance.resetForTest();
    Progress.instance.resetForTest();
    await ProfileStore.instance.load();
    left = CanvasController(canvasWidth: w, canvasHeight: h);
    right = CanvasController(canvasWidth: w, canvasHeight: h);
  });

  tearDown(() async {
    left.dispose();
    right.dispose();
    await Progress.instance.flush();
    ProfileStore.instance.resetForTest();
    Progress.instance.resetForTest();
    Settings.instance.resetForTest();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  TwoPainterSaveSession session() => TwoPainterSaveSession(
        left: left,
        right: right,
        paneWidth: w,
        paneHeight: h,
      );

  /// One committed stroke, through the same pointer path the panes use.
  void paint(CanvasController c, {int pointer = 1}) {
    c.pointerDown(PointerDownEvent(
        pointer: pointer,
        kind: PointerDeviceKind.touch,
        position: const Offset(8, 8)));
    c.pointerMove(PointerMoveEvent(
        pointer: pointer,
        kind: PointerDeviceKind.touch,
        position: const Offset(40, 60)));
    c.pointerUp(PointerUpEvent(
        pointer: pointer,
        kind: PointerDeviceKind.touch,
        position: const Offset(40, 60)));
  }

  List<Directory> saved() {
    final dir = Directory('${root.path}/artworks');
    return dir.existsSync()
        ? dir.listSync().whereType<Directory>().toList()
        : <Directory>[];
  }

  test('an untouched screen never becomes a picture', () async {
    final s = session();
    expect(s.isEmpty, isTrue);

    await s.save();

    expect(saved(), isEmpty,
        reason: 'opening the mode and walking away is not a painting');
  });

  test('a painted half is written with all its parts', () async {
    paint(left);
    await session().save();

    final dir = saved().single;
    expect(File('${dir.path}/paint.png').existsSync(), isTrue);
    expect(File('${dir.path}/thumb.png').existsSync(), isTrue);
    expect(File('${dir.path}/meta.json').existsSync(), isTrue);
  });

  test('repeated autosaves update one picture instead of piling up',
      () async {
    final s = session();
    paint(left);

    for (var i = 0; i < 4; i++) {
      paint(right, pointer: i + 2);
      await s.save();
    }

    expect(saved(), hasLength(1),
        reason: 'a fresh id per save would fill the gallery with copies '
            'of the same picture, one every thirty seconds');
  });

  test('both halves land in the same picture', () async {
    paint(left);
    paint(right, pointer: 2);
    final s = session();

    await s.save();

    expect(saved(), hasLength(1));
    final meta = File('${saved().single.path}/meta.json').readAsStringSync();
    expect(meta, contains('"width":${w * 2}'),
        reason: 'the two panes are stitched into one wide picture');
  });

  test('a save clears the dirty flags, so the timer stays quiet when idle',
      () async {
    paint(left);
    final s = session();
    expect(s.isDirty, isTrue);

    await s.save();

    expect(s.isDirty, isFalse);
  });

  test('concurrent saves are serialized, not interleaved', () async {
    paint(left);
    final s = session();

    // Timer, lifecycle hook and leaving, all at once.
    await Future.wait([s.save(), s.save(), s.save()]);

    expect(saved(), hasLength(1));
    final meta = File('${saved().single.path}/meta.json').readAsStringSync();
    expect(() => meta.isNotEmpty && meta.startsWith('{'), returnsNormally,
        reason: 'overlapping writes would leave meta.json unparseable');
  });

  test('a failed write keeps the picture dirty so the next tick retries',
      () async {
    paint(left);
    final s = session();
    // A directory where thumb.png belongs fails the write the way a full
    // disk does.
    final dir = Directory('${root.path}/artworks/${s.artworkId}')
      ..createSync(recursive: true);
    final blocker = Directory('${dir.path}/thumb.png')..createSync();

    await s.save();
    expect(s.isDirty, isTrue);

    blocker.deleteSync();
    await s.save();
    expect(s.isDirty, isFalse);
  });

  test('the id survives the session, so leaving updates the autosaved file',
      () async {
    final s = session();
    paint(left);
    await s.save();
    final firstId = saved().single.path.split(Platform.pathSeparator).last;

    // What _leave() does after a few autosaves have already run.
    paint(right, pointer: 2);
    await s.save();

    expect(saved(), hasLength(1));
    expect(saved().single.path.split(Platform.pathSeparator).last, firstId);
    expect(s.artworkId, firstId);
  });
}
