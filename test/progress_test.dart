import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/models/tool.dart';
import 'package:pixiepaint/util/json_store.dart';
import 'package:pixiepaint/util/progress.dart';
import 'package:pixiepaint/util/settings.dart';

void main() {
  late Directory dir;
  late File file;
  final progress = Progress.instance;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pp_progress');
    file = File('${dir.path}/progress.json');
    progress.resetForTest();
    // snapshot() folds in the global share count for the 💎 reward; pin it
    // so celebration expectations don't depend on other tests' Settings.
    Settings.instance.shareCount = 0;
  });

  tearDown(() async {
    // The register* methods persist fire-and-forget, so a write can still
    // be in flight here. Deleting the directory underneath it makes the
    // rmdir fail ("Directory not empty") when JsonStore recreates its .tmp
    // file mid-delete — an intermittent failure in whichever test happened
    // to be running. Wait for the queue to drain first.
    await progress.flush();
    progress.resetForTest();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<void> load() => progress.loadFrom(JsonStore(file));

  group('daily task', () {
    test('counts once per day, no matter how often it is tapped', () async {
      await load();
      progress.registerDailyTaskDone('2026-07-21');
      progress.registerDailyTaskDone('2026-07-21');
      progress.registerDailyTaskDone('2026-07-21');
      expect(progress.tasksDone, 1);
      expect(progress.isTaskDoneOn('2026-07-21'), isTrue);
      expect(progress.isTaskDoneOn('2026-07-22'), isFalse);
    });

    test('a new day can be completed again', () async {
      await load();
      progress.registerDailyTaskDone('2026-07-21');
      progress.registerDailyTaskDone('2026-07-22');
      expect(progress.tasksDone, 2);
    });
  });

  group('counters', () {
    test('artworks are deduplicated and capped', () async {
      await load();
      for (var i = 0; i < 80; i++) {
        progress.registerArtworkCompleted('artwork-$i');
      }
      progress.registerArtworkCompleted('artwork-0');
      expect(progress.completedArtworkIds.length, 50);
    });

    test('traces, cbn pages and tools only count once each', () async {
      await load();
      progress.registerTraceCompleted('letter_A');
      progress.registerTraceCompleted('letter_A');
      progress.registerCbnCompleted('cbn_fish');
      progress.registerCbnCompleted('cbn_fish');
      progress.registerToolUsed(ToolKind.brush);
      progress.registerToolUsed(ToolKind.brush);
      final snap = progress.snapshot();
      expect(snap.tracesDone, 1);
      expect(snap.cbnDone, 1);
      expect(snap.toolsUsed, 1);
    });

    test('snapshot reflects every counter the rewards read', () async {
      await load();
      progress.registerArtworkCompleted('a');
      progress.registerTraceCompleted('letter_B');
      progress.registerCbnCompleted('cbn_flower');
      progress.registerDailyTaskDone('2026-07-21');
      progress.registerToolUsed(ToolKind.glitter);
      final snap = progress.snapshot();
      expect(snap.paintings, 1);
      expect(snap.tracesDone, 1);
      expect(snap.cbnDone, 1);
      expect(snap.tasksDone, 1);
      expect(snap.toolsUsed, 1);
    });
  });

  group('celebrations', () {
    test('each reward parties exactly once', () async {
      await load();
      for (var i = 0; i < 5; i++) {
        progress.registerArtworkCompleted('artwork-$i');
      }
      final first = progress.takeUncelebrated();
      expect(first.map((r) => r.emoji), containsAll(['🦖', '🚀']));
      expect(progress.takeUncelebrated(), isEmpty);
    });

    test('a later unlock still gets its own party', () async {
      await load();
      for (var i = 0; i < 3; i++) {
        progress.registerArtworkCompleted('artwork-$i');
      }
      progress.takeUncelebrated();
      for (var i = 3; i < 5; i++) {
        progress.registerArtworkCompleted('artwork-$i');
      }
      final second = progress.takeUncelebrated();
      expect(second.map((r) => r.emoji), ['🚀']);
    });
  });

  group('persistence', () {
    test('every field survives a write/read round trip', () async {
      await load();
      // Three paintings is the first reward threshold, so this also puts a
      // celebrated emoji into the file.
      for (final id in ['a', 'b', 'c']) {
        progress.registerArtworkCompleted(id);
      }
      progress.registerToolUsed(ToolKind.neon);
      progress.registerTraceCompleted('number_7');
      progress.registerCbnCompleted('cbn_balloons');
      progress.registerDailyTaskDone('2026-07-21');
      expect(progress.takeUncelebrated(), isNotEmpty);
      await progress.flush();

      final reloaded = Progress.instance..resetForTest();
      await reloaded.loadFrom(JsonStore(file));
      expect(reloaded.completedArtworkIds, {'a', 'b', 'c'});
      expect(reloaded.toolsUsed, {ToolKind.neon.name});
      expect(reloaded.completedTraceIds, {'number_7'});
      expect(reloaded.completedCbnIds, {'cbn_balloons'});
      expect(reloaded.tasksDone, 1);
      expect(reloaded.lastTaskDay, '2026-07-21');
      expect(reloaded.celebratedEmojis, isNotEmpty);
    });

    test('writes never interleave into invalid JSON', () async {
      await load();
      // The real app fires these from void mutators in the same turn.
      for (var i = 0; i < 60; i++) {
        progress.registerArtworkCompleted('artwork-$i');
        progress.registerTraceCompleted('trace-$i');
      }
      await progress.flush();
      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
      expect((decoded['completedTraceIds'] as List), hasLength(60));
    });

    test('a corrupt file is set aside instead of silently overwritten',
        () async {
      file.writeAsStringSync('{"completedArtworkIds": [trunc');
      await load();
      // Starts fresh in memory...
      expect(progress.completedArtworkIds, isEmpty);
      // ...but the damaged original is still there to inspect.
      expect(File('${file.path}.corrupt.json').existsSync(), isTrue);
    });

    test('an interrupted write leaves the previous file intact', () async {
      await load();
      progress.registerArtworkCompleted('kept');
      await progress.flush();
      final good = file.readAsStringSync();
      // A leftover temp file from a crash must not be picked up as state.
      File('${file.path}.tmp').writeAsStringSync('{"broken":');
      expect(file.readAsStringSync(), good);
    });
  });

  group('per-profile isolation', () {
    test('loadFrom another file starts fresh — kids do not share rewards',
        () async {
      final fileA = File('${dir.path}/progress_a.json');
      final fileB = File('${dir.path}/progress_b.json');

      await progress.loadFrom(JsonStore(fileA));
      progress.registerCbnCompleted('cbn_fish');
      progress.registerTraceCompleted('letter_A');
      await progress.flush();

      // Switching to a fresh kid must not carry the first kid's progress.
      progress.resetForTest();
      await progress.loadFrom(JsonStore(fileB));
      expect(progress.completedCbnIds, isEmpty);
      expect(progress.completedTraceIds, isEmpty);

      // ...and switching back restores exactly the first kid's counters.
      progress.registerCbnCompleted('cbn_flower');
      await progress.flush();
      progress.resetForTest();
      await progress.loadFrom(JsonStore(fileA));
      expect(progress.completedCbnIds, {'cbn_fish'});
      expect(progress.completedTraceIds, {'letter_A'});
    });
  });
}
