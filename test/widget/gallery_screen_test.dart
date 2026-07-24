import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/gallery/artwork_store.dart';
import 'package:pixiepaint/gallery/gallery_screen.dart';
import 'package:pixiepaint/ui/bouncy.dart';
import 'package:pixiepaint/util/settings.dart';

import 'harness.dart';

/// The gallery is where pictures leave the app or stop existing: delete,
/// share, print, save-to-photos. That the parental gate itself works is
/// covered by parental_gate_test.dart — what matters here is that it
/// actually stands in front of the destructive paths, and that "keep it"
/// really keeps.
void main() {
  late Directory root;

  /// A saved artwork, written the way the canvas writes one.
  Future<void> makeArtwork(
    WidgetTester tester, {
    required String id,
    String? name,
    bool favorite = false,
  }) async {
    await tester.runAsync(() async {
      final png = Uint8List.fromList(List.filled(32, 3));
      final result = await ArtworkStore.save(
        id: id,
        pageId: 'cat',
        width: 64,
        height: 48,
        paintPng: png,
        thumbPng: png,
      );
      if (name != null || favorite) {
        await ArtworkStore.updateMeta(
          result.artwork.copyWith(name: name, favorite: favorite),
        );
      }
    });
  }

  Directory dirOf(String id) => Directory('${root.path}/artworks/$id');

  /// The gallery loads its list from disk in initState. Real file I/O never
  /// completes inside the fake-async zone of `testWidgets`, so the whole
  /// build has to happen in `runAsync` — otherwise the screen stays on its
  /// loading pixie forever and every finder comes up empty.
  Future<void> start(WidgetTester tester) async {
    await tester.runAsync(() async {
      await pumpPixie(tester, const GalleryScreen(),
          size: const Size(500, 1000));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    // Back in fake time: let the entrance animation finish.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Advances a dialog or sheet past its entrance animation.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  /// For steps that write to disk: run the real work, then repaint.
  ///
  /// A fixed pause is only honest where the assertion afterwards is that
  /// *nothing* happened (see the "keep it" test) — there is no condition to
  /// wait for, only a window in which the wrong thing could still occur.
  Future<void> flush(WidgetTester tester) async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }

  /// Waits until [done] holds — for real file I/O started inside the
  /// fake-async zone.
  ///
  /// This replaces a fixed 100 ms pause that had been in the delete test for
  /// several releases. It passed every time until a loaded machine (three
  /// test runs back to back) made the deletion take longer than the guess,
  /// and then it failed in about half of all runs. A delay is a guess; a
  /// condition is the thing actually being waited for.
  Future<void> waitUntil(
    WidgetTester tester,
    bool Function() done, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(timeout);
      while (!done() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
  }

  /// Opens the per-picture action sheet — that is a *long* press; a plain
  /// tap opens the picture for painting. The gesture has to land on the card
  /// itself, because the name sits inside a rotated polaroid frame.
  Future<void> openSheet(WidgetTester tester, String name) async {
    await tester.longPress(
      find.ancestor(of: find.text(name), matching: find.byType(Bouncy)).first,
      warnIfMissed: false,
    );
    await settle(tester);
  }

  testWidgets('saved pictures show up, an empty gallery says so',
      (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));

    await start(tester);
    expect(find.textContaining('Noch keine Bilder'), findsOneWidget);
  });

  testWidgets('the favorites filter hides everything else', (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    await makeArtwork(tester, id: 'a', name: 'Katze', favorite: true);
    await makeArtwork(tester, id: 'b', name: 'Hund');

    await start(tester);
    expect(find.text('Katze'), findsOneWidget);
    expect(find.text('Hund'), findsOneWidget);

    // The chip reads '❤️ Favoriten'.
    await tester.tap(find.textContaining('Favoriten'));
    await flush(tester);
    await settle(tester);

    expect(find.text('Katze'), findsOneWidget);
    expect(find.text('Hund'), findsNothing);
  });

  testWidgets('deleting asks first, and "keep it" keeps the picture',
      (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    Settings.instance.deleteNeedsGate = false;
    await makeArtwork(tester, id: 'a', name: 'Katze');

    await start(tester);
    await openSheet(tester, 'Katze');
    await tester.tap(find.text('Wegwerfen'));
    await settle(tester);

    // The confirmation is up; choose to keep.
    expect(find.text('Bild wegwerfen?'), findsOneWidget);
    await tester.tap(find.text('Behalten!'));
    await settle(tester);
    await flush(tester);

    expect(dirOf('a').existsSync(), isTrue,
        reason: 'the one answer that must never delete anything');
  });

  testWidgets('confirming the delete really removes it', (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    Settings.instance.deleteNeedsGate = false;
    await makeArtwork(tester, id: 'a', name: 'Katze');

    await start(tester);
    await openSheet(tester, 'Katze');
    await tester.tap(find.text('Wegwerfen'));
    await settle(tester);
    // The destructive choice is the quiet text button, not the big one.
    await tester.tap(find.widgetWithText(TextButton, 'Wegwerfen'));
    await settle(tester);
    await waitUntil(tester, () => !dirOf('a').existsSync());

    // The listing is in the message on purpose: this assertion has flaked
    // under load, and "isFalse is not isTrue" says nothing about why. What
    // is left in the directory does — a stray .tmp file would point at a
    // write that was still in flight, an empty directory at a delete that
    // got half-way.
    final leftovers = dirOf('a').existsSync()
        ? dirOf('a').listSync().map((e) => e.path.split('/').last).toList()
        : const <String>[];
    expect(dirOf('a').existsSync(), isFalse,
        reason: 'the picture directory is still there, containing: $leftovers');
  });

  testWidgets('with the parent setting on, deleting hits the gate first',
      (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    Settings.instance.deleteNeedsGate = true;
    await makeArtwork(tester, id: 'a', name: 'Katze');

    await start(tester);
    await openSheet(tester, 'Katze');
    await tester.tap(find.text('Wegwerfen'));
    await settle(tester);

    // The multiplication question, not the delete confirmation.
    expect(find.text('Frag deine Eltern!'), findsOneWidget);
    expect(find.text('Bild wegwerfen?'), findsNothing,
        reason: 'a child must not reach the delete dialog on their own');

    await tester.tap(find.text('Abbrechen'));
    await settle(tester);
    expect(dirOf('a').existsSync(), isTrue);
  });

  testWidgets('sharing is behind the gate too', (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    await makeArtwork(tester, id: 'a', name: 'Katze');

    await start(tester);
    await openSheet(tester, 'Katze');
    await tester.tap(find.textContaining('Teilen'));
    await settle(tester);

    expect(find.text('Frag deine Eltern!'), findsOneWidget);
  });

  testWidgets('the rename dialog opens prefilled and takes a new name',
      (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));
    await makeArtwork(tester, id: 'a', name: 'Katze');

    await start(tester);
    await openSheet(tester, 'Katze');
    await tester.tap(find.text('Umbenennen'));
    await settle(tester);

    // Prefilled with the current name, so a small correction is one edit.
    expect(find.widgetWithText(TextField, 'Katze'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Mein Kater');
    await tester.tap(find.text('Speichern'));
    await settle(tester);

    // The dialog is gone and nothing threw on the way out — that last part
    // is the point: the field used to free its controller while the close
    // animation was still rebuilding it.
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
    // That the new name reaches meta.json is ArtworkStore.updateMeta's job
    // and is covered in artwork_store_test.dart; a widget test cannot wait
    // for that write, because it is issued inside the fake-async zone.
  });
}
