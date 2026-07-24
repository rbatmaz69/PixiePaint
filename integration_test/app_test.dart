import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pixiepaint/gallery/artwork_store.dart';
import 'package:pixiepaint/l10n/app_localizations.dart';
import 'package:pixiepaint/main.dart' as app;
import 'package:pixiepaint/models/artwork.dart';
import 'package:pixiepaint/models/coloring_page.dart';
import 'package:pixiepaint/util/error_log.dart';

/// The one path that must never break, driven on a real device: open a
/// coloring page, paint on it, leave — and the picture is on disk afterwards.
///
/// This is the mechanical top of `docs/geraetetest.md`, the part worth
/// automating: it says nothing about whether the app *feels* right (that is
/// still a person with a tablet), but it proves that the whole chain from tap
/// to file works on this device, this OS version, this screen size.
///
/// Run it against a connected device or a simulator:
///
///     flutter test integration_test/app_test.dart -d <geräte-id>
///
/// It runs against real app data. It therefore only ever *adds* one picture
/// and removes exactly that one again at the end.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps frames without settling.
  ///
  /// `pumpAndSettle` cannot be used here: the blob background animates on a
  /// 28-second ticker, so the tree never goes quiet and settling would run
  /// into its timeout instead of finding the screen.
  Future<void> settle(WidgetTester tester,
      {int frames = 20, int ms = 100}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(Duration(milliseconds: ms));
    }
  }

  /// The app's own texts, read out of the running tree — so this test works on
  /// a Turkish device as well as a German one.
  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(Navigator).first))!;

  testWidgets('paint a coloring page and find it on disk afterwards',
      (tester) async {
    final before = (await ArtworkStore.list()).map((a) => a.id).toSet();

    app.main();
    await settle(tester, frames: 40);

    final texts = l10n(tester);

    // The welcome runs on a fresh install only, so both cases have to work.
    final skip = find.text(texts.welcomeSkip);
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await settle(tester);
    } else {
      await tester.tap(find.text(texts.cardColoring));
      await settle(tester);
    }

    // The picker: every tile carries a Hero tagged with the page id, which is
    // a far steadier handle than a position in a grid.
    final pages = await ColoringPage.loadAll();
    final first = pages.first;
    final tile = find.byWidgetPredicate(
        (w) => w is Hero && w.tag == first.id,
        description: 'tile for "${first.id}"');
    expect(tile, findsOneWidget,
        reason: 'the picture picker did not open, or it is empty');
    await tester.tap(tile);
    await settle(tester, frames: 40);

    // Paint: a diagonal drag across the middle of the canvas.
    final canvas = tester.getCenter(find.byType(Scaffold).last);
    final gesture = await tester.startGesture(canvas - const Offset(60, 60));
    for (var i = 1; i <= 12; i++) {
      await gesture.moveTo(canvas + Offset(i * 8.0 - 60, i * 8.0 - 60));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await settle(tester);

    // Leaving saves — that is the promise autosave makes.
    await tester.pageBack();
    await settle(tester, frames: 40);

    final after = await ArtworkStore.list();
    final fresh = after.where((a) => !before.contains(a.id)).toList();
    expect(fresh, hasLength(1),
        reason: 'painting and leaving did not produce exactly one picture');

    final artwork = fresh.single;
    expect(File(artwork.paintFile.path).existsSync(), isTrue,
        reason: 'paint.png missing — the picture exists only in the list');
    expect(File('${artwork.dirPath}/meta.json').existsSync(), isTrue,
        reason: 'meta.json missing — it is the commit marker of a save');
    expect(artwork.pageId, first.id);

    // The app's own error log is the assertion here: nothing may have been
    // recorded while all of the above happened. Note that `main()` installs
    // its handlers over the test framework's, so a framework error would land
    // there rather than failing a check above.
    expect(ErrorLog.instance.entries.map((e) => e.message).toList(), isEmpty,
        reason: 'the app recorded an error during the run');

    // Put the device back the way it was.
    await ArtworkStore.delete(artwork);
    expect((await ArtworkStore.list()).map((a) => a.id).toSet(), before);
  });

  testWidgets('the gallery shows what was painted', (tester) async {
    // Deliberately its own run: it starts the app again, which is the closest
    // an integration test gets to the restart the checklist asks for.
    final artwork = await _seedArtwork();
    addTearDown(() => ArtworkStore.delete(artwork));

    app.main();
    await settle(tester, frames: 40);

    final texts = l10n(tester);
    final skip = find.text(texts.welcomeSkip);
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await settle(tester);
      await tester.pageBack();
      await settle(tester);
    }

    await tester.tap(find.text(texts.cardGallery));
    await settle(tester, frames: 40);

    expect(find.byType(Image), findsWidgets,
        reason: 'the gallery shows no thumbnail for a saved picture');
    expect(ErrorLog.instance.isEmpty, isTrue);
  });
}

/// Writes one picture straight through the store, so the gallery has
/// something to show without painting it again.
Future<Artwork> _seedArtwork() async {
  final result = await ArtworkStore.save(
    id: ArtworkStore.newId(),
    pageId: null,
    width: 64,
    height: 48,
    paintPng: _tinyPng,
    thumbPng: _tinyPng,
  );
  if (!result.ok) {
    throw StateError('could not seed an artwork — the save reported failure');
  }
  return result.artwork;
}

/// A 1×1 transparent PNG — enough to be a valid file on disk.
final Uint8List _tinyPng = Uint8List.fromList(const [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
  0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84,
  120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69,
  78, 68, 174, 66, 96, 130,
]);
