import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/gallery/home_screen.dart';
import 'package:pixiepaint/ui/bouncy.dart';

import 'harness.dart';

/// The home screen is a grid of big cards, and it is meant to be two across
/// on a phone — the code that sizes them says so in as many words, and its
/// clamp exists to stop the grid "collapsing into a six-item list".
///
/// It collapsed anyway, on every device, for a reason nothing on this screen
/// could see: [Bouncy] wrapped its child in a plain [Center] to guarantee a
/// 48 px hit area, and a Center fills whatever room it is offered. Inside a
/// [Wrap] — which offers the whole row — every card claimed a full line.
void main() {
  late Directory root;

  Future<void> start(WidgetTester tester, Size size) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));
    await tester.runAsync(() async {
      await pumpPixie(tester, const HomeScreen(), size: size);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Left edges of the cards, grouped by the row they landed on.
  List<List<double>> rows(WidgetTester tester) {
    final wrap = (find.byType(Wrap).evaluate().single.widget as Wrap);
    final byTop = <int, List<double>>{};
    for (final child in wrap.children) {
      final rect = tester.getRect(find.byWidget(child));
      byTop.putIfAbsent(rect.top.round(), () => []).add(rect.left);
    }
    final tops = byTop.keys.toList()..sort();
    return [for (final t in tops) byTop[t]!..sort()];
  }

  testWidgets('the cards stand two across on a small phone', (tester) async {
    await start(tester, const Size(360, 640));

    final grid = rows(tester);
    expect(grid.first, hasLength(2),
        reason: 'a single card per row is the collapse the clamp guards against');
    // Six of the seven pair up; the odd one sits alone on the last line.
    expect(grid.where((r) => r.length == 2).length, greaterThanOrEqualTo(3));
  });

  testWidgets('a card is not as wide as the row it sits in', (tester) async {
    await start(tester, const Size(390, 780));

    final wrap = (find.byType(Wrap).evaluate().single.widget as Wrap);
    final rowWidth = tester.getSize(find.byType(Wrap)).width;
    final cardWidth = tester.getRect(find.byWidget(wrap.children.first)).width;

    expect(cardWidth, lessThan(rowWidth / 2 + 1),
        reason: 'the entrance wrapper must hug the card, not the row');
  });

  testWidgets('a Bouncy still guarantees its 48 px hit area', (tester) async {
    root = await setUpPixieStorage(tester);
    addTearDown(() => tearDownPixieStorage(tester, root));
    // The whole reason the Center is there: a tiny child must still be
    // large enough for a small finger.
    await pumpPixie(
      tester,
      Center(
        child: Bouncy(
          onTap: () {},
          child: const SizedBox(width: 8, height: 8),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Bouncy)), const Size(48, 48));
  });
}
