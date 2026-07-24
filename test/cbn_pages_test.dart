import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/region_label.dart';
import 'package:pixiepaint/models/cbn_spec.dart';
import 'package:pixiepaint/util/svg_raster.dart';

/// End-to-end authoring check for the color-by-number content: rasterizes
/// each bundled CbN page exactly like the app does, labels its regions and
/// asserts that every sidecar label lands inside a real enclosed region.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const w = 2048, h = 1536;

  /// Read out of the catalog rather than listed here: the four pages of v6.3
  /// were hardcoded, and the four added in v7.6 would have slipped straight
  /// past this test.
  final pages = (jsonDecode(
              File('assets/coloring_pages/pages.json').readAsStringSync())
          as List)
      .cast<Map<String, dynamic>>()
      .where((e) => e['mode'] == 'cbn')
      .map((e) => e['id'] as String)
      .toList();

  test('the catalog has color-by-number pages at all', () {
    // Guards the derivation above: a renamed `mode` value would otherwise
    // turn this whole file into zero tests that all pass.
    expect(pages, hasLength(8));
  });

  for (final id in pages) {
    test('$id: every label sits in a valid, consistently numbered region',
        () async {
      final art =
          await rasterizeSvgAsset('assets/coloring_pages/$id.svg', w, h);
      final regions = labelRegions(art.barrierAlpha, w, h);
      final spec = await CbnSpec.load(id);
      expect(spec, isNotNull, reason: 'missing sidecar for $id');

      final numberOfRegion = <int, int>{};
      for (final label in spec!.labels) {
        final x = label.pos.dx.floor();
        final y = label.pos.dy.floor();
        final region = regions[y * w + x];
        expect(region, isNot(0),
            reason:
                '$id: label ${label.number} at (${label.pos.dx}, ${label.pos.dy}) sits on an outline');
        final existing = numberOfRegion[region];
        expect(existing ?? label.number, label.number,
            reason:
                '$id: region $region carries two numbers ($existing and ${label.number}) — regions leak into each other');
        numberOfRegion[region] = label.number;
      }

      // The outer background must stay unlabeled (free-fill area).
      expect(numberOfRegion.containsKey(regions[0]), isFalse,
          reason: '$id: a label leaked into the outer background region');

      art.dispose();
    });
  }
}
