import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/gallery/artwork_store.dart';
import 'package:pixiepaint/gallery/continue_card.dart';
import 'package:pixiepaint/gallery/page_picker_screen.dart';
import 'package:pixiepaint/util/progress.dart';

import 'harness.dart';

/// Finding the way back.
///
/// Two shortcuts, one question: can a child who cannot read get back to
/// something they were doing? Yesterday's picture, and the motif they keep
/// asking for.
void main() {
  late Directory root;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  /// A saved picture, written the way the canvas writes one. Saves are
  /// stamped with the wall clock, so calling this twice in order is what
  /// makes the second one "the last picture".
  Future<void> makeArtwork(
    WidgetTester tester, {
    required String id,
    String? name,
    String? profileId,
  }) async {
    await tester.runAsync(() async {
      final png = Uint8List.fromList(List.filled(32, 3));
      final result = await ArtworkStore.save(
        id: id,
        pageId: 'cat',
        profileId: profileId,
        width: 64,
        height: 48,
        paintPng: png,
        thumbPng: png,
      );
      if (name != null) {
        await ArtworkStore.updateMeta(result.artwork.copyWith(name: name));
      }
    });
  }

  /// Real file I/O never completes inside the fake-async zone of
  /// `testWidgets`, and both widgets here read from disk while they build.
  Future<void> start(WidgetTester tester, Widget screen, Size size) async {
    await tester.runAsync(() async {
      await pumpPixie(tester, screen, size: size);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await settle(tester);
  }

  group('favorite pictures in the picker', () {
    testWidgets('the hearts tab appears only once something is in it',
        (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(tester, root));

      await start(tester, const PagePickerScreen(), const Size(500, 900));

      // A child who has never hearted anything must not meet an empty tab.
      expect(find.text('💖'), findsNothing);
      expect(find.text('Alle'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await settle(tester);

      expect(find.text('💖'), findsOneWidget);
      expect(Progress.instance.favoritePageIds, hasLength(1));
    });

    testWidgets('the heart fills in and can be taken back', (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(tester, root));

      await start(tester, const PagePickerScreen(), const Size(500, 900));

      await tester.tap(find.byIcon(Icons.favorite_border_rounded).first);
      await settle(tester);
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

      await tester.tap(find.byIcon(Icons.favorite_rounded).first);
      await settle(tester);

      expect(Progress.instance.favoritePageIds, isEmpty);
      expect(find.text('💖'), findsNothing,
          reason: 'the tab goes away with the last heart');
    });
  });

  group('marks on a picture tile', () {
    /// The picker resolves two futures in sequence — the pictures, then the
    /// gallery it derives the stars from — so it needs a second real-time
    /// window after [start] before the marks are on screen.
    Future<void> settleBadges(WidgetTester tester) async {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await settle(tester);
    }

    testWidgets('a numbered picture says so, an ordinary one does not',
        (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(tester, root));

      await start(tester, const PagePickerScreen(), const Size(500, 900));
      await settleBadges(tester);

      // On "Alle" the numbered pictures sit at index 38 and further, well
      // below what a lazily built grid has made yet.
      expect(find.bySemanticsLabel('Malen nach Zahlen'), findsNothing);

      // Eight of the sixty-eight open into a different screen — bucket
      // forced, palette replaced by numbers, most tools switched off — and
      // their tiles used to look exactly like the rest.
      //
      // Driven through the controller rather than by tapping the tab: with
      // eleven categories the strip scrolls, and "Zahlen" is off its right
      // edge at this window size.
      final tabs = tester.widgetList<Tab>(find.byType(Tab)).toList();
      final controller =
          DefaultTabController.of(tester.element(find.byType(TabBarView)));
      controller.index = tabs.indexWhere((t) => t.text == 'Zahlen');
      await settleBadges(tester);

      expect(find.bySemanticsLabel('Malen nach Zahlen'), findsWidgets);
    });

    testWidgets('a picture this child has painted gets a star',
        (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(tester, root));

      await start(tester, const PagePickerScreen(), const Size(500, 900));
      await settleBadges(tester);
      expect(find.bySemanticsLabel('Schon gemalt'), findsNothing);

      // makeArtwork saves against pageId 'cat', which is the first tile.
      // Pumping the picker again reuses the same State, so the reload has
      // to be asked for the way returning from the canvas asks for it.
      await makeArtwork(tester, id: 'a1');
      // All of it inside runAsync: didPopNext starts a real disk read, a
      // future created in the fake-async zone would never complete, and the
      // frame in between is what lets the FutureBuilder subscribe to the
      // new future while there is still real time left to finish it.
      await tester.runAsync(() async {
        (tester.state(find.byType(PagePickerScreen)) as RouteAware)
            .didPopNext();
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await tester.pump();
      });
      await settle(tester);

      expect(find.bySemanticsLabel('Schon gemalt'), findsOneWidget);
    });
  });

  group('the keep-painting card', () {
    const card = Scaffold(body: Center(child: ContinueCard(width: 300)));

    testWidgets('stays away on a device with no pictures yet', (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(tester, root));

      await start(tester, card, const Size(400, 800));

      expect(find.text('Weitermalen'), findsNothing);
    });

    testWidgets('offers the picture this child painted last', (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(tester, root));
      await makeArtwork(tester, id: 'older', name: 'Alt');
      await makeArtwork(tester, id: 'newer', name: 'Neu');

      await start(tester, card, const Size(400, 800));

      expect(find.text('Weitermalen'), findsOneWidget);
      expect(find.text('Neu'), findsOneWidget);
      expect(find.text('Alt'), findsNothing,
          reason: 'the shortcut is to the last picture, not to any picture');
    });

    testWidgets("ignores another child's pictures", (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(tester, root));
      await makeArtwork(tester,
          id: 'siblings', name: 'Vom Bruder', profileId: 'some-other-kid');

      await start(tester, card, const Size(400, 800));

      expect(find.text('Weitermalen'), findsNothing);
    });
  });
}
