import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixiepaint/canvas/region_label.dart';
import 'package:pixiepaint/models/coloring_page.dart';
import 'package:pixiepaint/util/svg_raster.dart';

/// Does every bundled picture actually work as a coloring page?
///
/// A drawing with a gap in its outline looks perfect and floods the whole
/// picture on the first tap — which no unit test of the fill algorithm would
/// ever catch, because the algorithm is right and the artwork is wrong. So
/// each SVG is rasterized exactly as the app does it, its regions are
/// labelled, and the result has to look like a coloring page.
///
/// Until v7.6 this ran over the twelve seasonal pages only (they were the
/// newest at the time). It now runs over the whole catalog: the acceptance
/// for a picture should not depend on which release added it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const w = 2048, h = 1536;

  final pages = (jsonDecode(
              File('assets/coloring_pages/pages.json').readAsStringSync())
          as List)
      .cast<Map<String, dynamic>>()
      .map((e) => ColoringPage(
            id: e['id'] as String,
            title: e['title'] as String,
            titleEn: e['titleEn'] as String?,
            file: e['file'] as String,
            category: e['category'] as String,
            categoryEn: e['categoryEn'] as String?,
            mode: e['mode'] as String?,
            season: e['season'] as String?,
          ))
      .toList();

  test('the catalog is complete', () {
    expect(pages, hasLength(68));
    for (final page in pages) {
      expect(File('assets/coloring_pages/${page.file}').existsSync(), isTrue,
          reason: '${page.id}: missing SVG');
      expect(page.titleEn, isNotNull, reason: '${page.id}: no English title');
      expect(kCategoryNames.containsKey(page.category), isTrue,
          reason: '${page.id}: category "${page.category}" has no '
              'translations in kCategoryNames');
    }
    // Ids address artworks on disk (meta.json keeps the pageId), so a
    // duplicate would quietly point two pictures at one file.
    expect(pages.map((p) => p.id).toSet(), hasLength(pages.length));
    expect(pages.map((p) => p.file).toSet(), hasLength(pages.length));
  });

  for (final page in pages) {
    test('${page.id} rasterizes into fillable, enclosed regions', () async {
      final art = await rasterizeSvgAsset(page.assetPath, w, h);
      final regions = labelRegions(art.barrierAlpha, w, h);

      // Region 0 is the outline itself; the background is whatever region the
      // top-left corner belongs to.
      final background = regions[0];
      final sizes = <int, int>{};
      for (final region in regions) {
        if (region == 0 || region == background) continue;
        sizes[region] = (sizes[region] ?? 0) + 1;
      }

      // Areas smaller than this are anti-aliasing crumbs between strokes,
      // not something a child could ever aim at.
      const minUsefulArea = 2000;
      final fillable = sizes.values.where((px) => px >= minUsefulArea).length;

      expect(fillable, greaterThanOrEqualTo(3),
          reason: '${page.id}: only $fillable fillable areas — an outline is '
              'probably open and the fill leaks into the background');

      // A gap in the outline shows up as a background that swallowed the
      // whole picture.
      final backgroundPixels = regions.where((r) => r == background).length;
      expect(backgroundPixels / regions.length, lessThan(0.9),
          reason: '${page.id}: the background covers the whole canvas');

      art.dispose();
    });
  }
}
