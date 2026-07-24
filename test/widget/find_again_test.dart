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
      addTearDown(() => tearDownPixieStorage(root));

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
      addTearDown(() => tearDownPixieStorage(root));

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

  group('the keep-painting card', () {
    const card = Scaffold(body: Center(child: ContinueCard(width: 300)));

    testWidgets('stays away on a device with no pictures yet', (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(root));

      await start(tester, card, const Size(400, 800));

      expect(find.text('Weitermalen'), findsNothing);
    });

    testWidgets('offers the picture this child painted last', (tester) async {
      root = await setUpPixieStorage(tester);
      addTearDown(() => tearDownPixieStorage(root));
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
      addTearDown(() => tearDownPixieStorage(root));
      await makeArtwork(tester,
          id: 'siblings', name: 'Vom Bruder', profileId: 'some-other-kid');

      await start(tester, card, const Size(400, 800));

      expect(find.text('Weitermalen'), findsNothing);
    });
  });
}
