import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/canvas_screen.dart';
import 'package:pixiepaint/gallery/home_screen.dart';
import 'package:pixiepaint/gallery/page_picker_screen.dart';
import 'package:pixiepaint/settings/settings_screen.dart';

import 'harness.dart';

/// Big system text.
///
/// The app clamps the system text scale (v8.3 raised the ceiling from 1.3
/// to 1.6), and this is what keeps that promise honest: at the ceiling, on
/// a small phone, nothing may overflow. A `RenderFlex overflowed` surfaces
/// in `testWidgets` as an exception, so `takeException` is the assertion.
void main() {
  late Directory root;

  Future<void> open(WidgetTester tester, Widget screen) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(root));

    await tester.runAsync(() async {
      await pumpPixie(tester, screen,
          size: const Size(360, 640), textScale: 1.6);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(tester.takeException(), isNull);
  }

  testWidgets('the home screen holds together', (tester) async {
    await open(tester, const HomeScreen());
  });

  testWidgets('the settings screen holds together', (tester) async {
    await open(tester, const SettingsScreen());
  });

  testWidgets('the picture picker holds together', (tester) async {
    await open(tester, const PagePickerScreen());
  });

  testWidgets('the painting screen holds together', (tester) async {
    await open(tester, const CanvasScreen());
  });
}
