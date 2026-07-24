import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/gallery/gallery_screen.dart';
import 'package:pixiepaint/gallery/page_picker_screen.dart';
import 'package:pixiepaint/gallery/slideshow_screen.dart';
import 'package:pixiepaint/models/artwork.dart';
import 'package:pixiepaint/settings/error_log_screen.dart';

import 'harness.dart';

/// Leaving a screen again straight away — before it has finished loading.
///
/// This is one bug repeated: an `AnimationController` declared `late final`
/// is created on first *use*, and screens that show a loading pixie while
/// they read from disk do not use theirs yet. Disposing such a screen then
/// creates the controller inside `dispose()`, in an element tree that is
/// already deactivated, and the app goes down. It cost three separate
/// crashes in this codebase (gallery, picture picker, slideshow), which is
/// two more than a pattern deserves before it gets a test.
///
/// Every screen here is built and torn down without ever settling. The
/// assertion is simply that nothing throws.
void main() {
  late Directory root;

  Future<void> openAndLeave(WidgetTester tester, Widget screen) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));

    await pumpPixie(tester, screen, size: const Size(420, 860));
    // One frame only: the loading state, nothing more.
    await tester.pump();

    // Replace the screen — this disposes it mid-load.
    await pumpPixie(tester, const SizedBox.shrink(),
        size: const Size(420, 860));
    await tester.pump();

    expect(tester.takeException(), isNull);
  }

  testWidgets('the gallery survives being left while it loads',
      (tester) async {
    await openAndLeave(tester, const GalleryScreen());
  });

  testWidgets('the picture picker survives being left while it loads',
      (tester) async {
    await openAndLeave(tester, const PagePickerScreen());
  });

  testWidgets('the problem report survives being left right away',
      (tester) async {
    // It owns no AnimationController at all — which is the point of listing
    // it here: the next person to add an entrance animation to this screen
    // meets the pattern and this test in the same place.
    await openAndLeave(tester, const ErrorLogScreen());
  });

  testWidgets('the slideshow survives being left while it loads',
      (tester) async {
    // One artwork is enough; its first slide renders at 1400 px, so the
    // loading state is what the single pump above sees.
    final artwork = Artwork(
      id: 'a',
      pageId: null,
      width: 64,
      height: 48,
      updatedAt: DateTime(2026),
      dirPath: '${Directory.systemTemp.path}/pp_missing',
    );
    await openAndLeave(tester, SlideshowScreen(artworks: [artwork]));
  });
}
