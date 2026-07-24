import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/util/error_log.dart';
import 'package:pixiepaint/util/json_store.dart';

/// The error log is the app's only memory of things going wrong, so its own
/// failure modes matter more than most: it must not grow without bound, must
/// not turn one repeating glitch into three hundred entries, must not leak
/// paths into a file a parent shares, and must survive its own file being
/// garbage.
void main() {
  late Directory dir;
  final log = ErrorLog.instance;

  File logFile() => File('${dir.path}/errors.log');

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pp_errorlog');
    log.resetForTest();
  });

  tearDown(() async {
    // The queue may still hold a write; deleting the directory under it is
    // what makes tests flaky here (see the JsonStore note in the README).
    await log.flush();
    log.resetForTest();
    onPersistFailure = null;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('an entry reaches the file and comes back on the next start', () async {
    await log.initIn(dir);
    log.record(StateError('kaputt'), StackTrace.current,
        origin: ErrorOrigin.flutter);
    await log.flush();

    expect(logFile().existsSync(), isTrue);

    // A second instance over the same directory is what the next app start
    // sees.
    log.resetForTest();
    await log.initIn(dir);
    expect(log.count, 1);
    expect(log.entries.single.message, contains('kaputt'));
    expect(log.entries.single.origin, ErrorOrigin.flutter);
    expect(log.entries.single.stack, isNotEmpty);
  });

  test('errors recorded before init survive it — startup failures matter most',
      () async {
    log.record(StateError('während des Starts'), null,
        origin: ErrorOrigin.zone);
    expect(log.count, 1, reason: 'recording must work without a directory');

    await log.initIn(dir);
    expect(log.count, 1);
    await log.flush();

    log.resetForTest();
    await log.initIn(dir);
    expect(log.entries.single.message, contains('während des Starts'));
  });

  test('the buffered entry lands after what the file already had', () async {
    await log.initIn(dir);
    log.record(StateError('älter'), null, origin: ErrorOrigin.flutter);
    await log.flush();

    log.resetForTest();
    // Recorded before init, so newer than the file's entry.
    log.record(StateError('neuer'), null, origin: ErrorOrigin.flutter);
    await log.initIn(dir);

    // entries is newest first.
    expect(log.entries.first.message, contains('neuer'));
    expect(log.entries.last.message, contains('älter'));
  });

  test('a repeat inside the window counts instead of piling up', () async {
    await log.initIn(dir);
    // What a throwing painter does: the same error once per frame.
    for (var i = 0; i < 200; i++) {
      log.record(StateError('jeden Frame'), StackTrace.current,
          origin: ErrorOrigin.flutter);
    }
    await log.flush();

    expect(log.count, 1);
    expect(log.entries.single.count, 200);
  });

  test('the same message through a different door still counts as a repeat',
      () async {
    // A throwing build reports to FlutterError.onError and then has its
    // replacement widget built — two origins, one failure.
    await log.initIn(dir);
    log.record(StateError('einmal'), null, origin: ErrorOrigin.flutter);
    log.record(StateError('einmal'), null, origin: ErrorOrigin.platform);
    await log.flush();

    expect(log.count, 1);
    expect(log.entries.single.count, 2);
  });

  test('a different message starts its own entry', () async {
    await log.initIn(dir);
    log.record(StateError('eins'), null, origin: ErrorOrigin.flutter);
    log.record(StateError('zwei'), null, origin: ErrorOrigin.flutter);
    await log.flush();

    expect(log.count, 2);
    expect(log.entries.first.message, contains('zwei'));
  });

  test('the entry ceiling drops the oldest, never the newest', () async {
    await log.initIn(dir);
    for (var i = 0; i < ErrorLog.maxEntries + 12; i++) {
      log.record(StateError('Fehler $i'), null, origin: ErrorOrigin.flutter);
    }
    await log.flush();

    expect(log.count, ErrorLog.maxEntries);
    expect(log.entries.first.message, contains('Fehler 41'));
    expect(
        log.entries.map((e) => e.message).where((m) => m.contains('Fehler 0')),
        isEmpty);
  });

  test('the byte ceiling holds even when the entries are huge', () async {
    await log.initIn(dir);
    final fatStack = StackTrace.fromString(
        List.generate(40, (i) => '#$i ${'x' * 400}').join('\n'));
    for (var i = 0; i < 20; i++) {
      log.record(StateError('groß $i'), fatStack, origin: ErrorOrigin.flutter);
    }
    await log.flush();

    expect(logFile().lengthSync(), lessThanOrEqualTo(ErrorLog.maxBytes));
    // ...and it kept the newest one rather than giving up entirely.
    expect(log.entries.first.message, contains('groß 19'));
  });

  test('the documents path never reaches the file', () async {
    await log.initIn(dir);
    log.record(
      FileSystemException('no space left', '${dir.path}/artworks/abc/paint.png'),
      StackTrace.fromString('#0 something (file://${dir.path}/lib/foo.dart:1)'),
      origin: ErrorOrigin.save,
      detail: '${dir.path}/artworks/abc/meta.json',
    );
    await log.flush();

    final raw = logFile().readAsStringSync();
    expect(raw, isNot(contains(dir.path)),
        reason: 'on iOS this path contains an install UUID, '
            'and its subpaths contain artwork ids');
    expect(raw, contains('<docs>'));
    expect(log.entries.single.detail, startsWith('<docs>'));
  });

  test('a long message is shortened to its first line', () async {
    await log.initIn(dir);
    log.record(
      StateError('erste Zeile\nzweite Zeile\ndritte Zeile'),
      null,
      origin: ErrorOrigin.flutter,
    );
    expect(log.entries.single.message, contains('erste Zeile'));
    expect(log.entries.single.message, isNot(contains('zweite Zeile')));

    log.record(StateError('y' * 900), null, origin: ErrorOrigin.flutter);
    expect(log.entries.first.message.length, lessThan(220));
  });

  test('the stack is cut to a readable number of frames', () async {
    await log.initIn(dir);
    log.record(
      StateError('tief'),
      StackTrace.fromString(List.generate(60, (i) => '#$i frame$i').join('\n')),
      origin: ErrorOrigin.flutter,
    );
    expect(log.entries.single.stack.split('\n'), hasLength(12));
  });

  test('a garbage line costs that line, not the log', () async {
    await log.initIn(dir);
    log.record(StateError('gut'), null, origin: ErrorOrigin.flutter);
    await log.flush();
    // A crash mid-write cannot produce this (the write is atomic), but a
    // half-flushed line is exactly what the line format is meant to survive.
    logFile().writeAsStringSync('\n{ nicht json', mode: FileMode.append);

    log.resetForTest();
    await log.initIn(dir);
    expect(log.count, 1);
    expect(log.entries.single.message, contains('gut'));
  });

  test('an absurdly large log file is dropped instead of parsed', () async {
    logFile().writeAsStringSync('x' * (600 * 1024));
    await log.initIn(dir);

    expect(log.count, 0);
    expect(logFile().existsSync(), isFalse);
  });

  test('clearing empties memory and file', () async {
    await log.initIn(dir);
    log.record(StateError('weg damit'), null, origin: ErrorOrigin.flutter);
    await log.flush();
    await log.clear();

    expect(log.isEmpty, isTrue);
    expect(logFile().readAsStringSync(), isEmpty);

    log.resetForTest();
    await log.initIn(dir);
    expect(log.count, 0);
  });

  test('the shared report carries the version and every entry', () async {
    await log.initIn(dir);
    log.record(StateError('erster'), null, origin: ErrorOrigin.flutter);
    log.record(StateError('zweiter'), null, origin: ErrorOrigin.save);

    final report = log.asReport(note: 'Hinweis für Eltern');
    expect(report, contains('PixiePaint'));
    expect(report, contains('Hinweis für Eltern'));
    expect(report, contains('erster'));
    expect(report, contains('zweiter'));
  });

  test('a failed write is recorded, and the log\'s own write is not',
      () async {
    // The hook json_store calls — main() points it at the log.
    onPersistFailure = (error, stack, path) => log
        .record(error, stack, origin: ErrorOrigin.save, detail: path);
    await log.initIn(dir);

    // A directory where a file should be: the rename fails, the way it does
    // when storage is full or a permission lapsed.
    final blocked = Directory('${dir.path}/blocked')..createSync();
    expect(await atomicWriteString(File(blocked.path), 'egal'), isFalse);
    await log.flush();

    expect(log.count, 1);
    expect(log.entries.single.origin, ErrorOrigin.save);

    // And now the important half: make the log's *own* file unwritable and
    // check that its failure does not record another entry, which would
    // fail, which would record — the loop `report: false` exists to prevent.
    log.resetForTest();
    final logDir = Directory('${dir.path}/nested');
    Directory('${logDir.path}/errors.log').createSync(recursive: true);
    await log.initIn(logDir);
    log.record(StateError('unschreibbar'), null, origin: ErrorOrigin.flutter);
    await log.flush();
    await log.flush();

    expect(log.count, 1, reason: 'a failing log write must not feed itself');
    expect(log.entries.single.message, contains('unschreibbar'));
  });
}
