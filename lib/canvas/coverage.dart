import 'dart:typed_data';

import 'magic_wand.dart' show kWandMinAlpha;

/// How much of a region has to carry paint before it counts as done. Well
/// below full: a child colours *roughly* inside the lines, and the ring of
/// bare paper a wobbly stroke leaves along the outline is the normal case,
/// not an unfinished one.
const double kRegionPainted = 0.5;

/// How much of a whole picture has to carry paint before it counts as a
/// finished painting for the sticker rewards.
///
/// Forgiving on purpose. This number replaces "was saved once", and the job
/// it has to do is tell a page a child worked on from a page they opened and
/// left — not to hold a three-year-old to an adult's idea of finished. Two
/// thirds of the areas coloured in clears it.
const double kPictureFinished = 0.6;

/// Regions smaller than this are ignored entirely. Where two lines run close
/// together the rasterizer leaves slivers of a few pixels that no brush can
/// reach — without this floor they would be "still empty" forever, and the
/// picture could never be finished.
const int kMinRegionPixels = 40;

/// A single enclosed area that is still bare, with the point to draw
/// attention to.
class EmptyRegion {
  const EmptyRegion({
    required this.id,
    required this.pixels,
    required this.x,
    required this.y,
  });

  final int id;

  /// Size of the whole region, not of the unpainted part — this is what
  /// orders the list, so the big obvious gaps come first.
  final int pixels;

  /// Where the hint goes. The centre of mass of the *unpainted* pixels,
  /// nudged onto one of them (see [regionCoverage]) so it never lands in
  /// the middle of a crescent, outside its own region.
  final double x;
  final double y;
}

/// What a scan of the picture found.
class CoverageReport {
  const CoverageReport({
    required this.fraction,
    required this.empty,
    required this.regions,
  });

  /// Painted share of all enclosed areas, 0..1. The background around the
  /// motif is not part of it — see [regionCoverage].
  final double fraction;

  /// Still-bare areas, biggest first.
  final List<EmptyRegion> empty;

  /// How many enclosed areas the picture has at all. Zero means there is
  /// nothing to measure here (free drawing, a photo, the scratch picture),
  /// and [fraction] is 0 by convention — callers must check this before
  /// reading anything into the number.
  final int regions;

  bool get hasRegions => regions > 0;

  /// Every area carries paint.
  bool get allPainted => regions > 0 && empty.isEmpty;
}

/// Measures how much of a coloring page has actually been painted.
///
/// Answers two questions with one pass: which enclosed areas are still bare
/// (the ✨ hint points at them) and how far along the picture is as a whole
/// (which is what makes the "finished a painting" reward mean something —
/// before this it counted any page that had been saved once).
///
/// [regionOf] comes from `labelRegions`, [rgba] is the paint layer in
/// premultiplied RGBA. Pure Dart, no dart:ui — safe for `Isolate.run`.
///
/// Three decisions worth knowing:
///
/// * **Paint is `alpha >= kWandMinAlpha`** — the same constant the magic
///   wand uses to tell paint from paper, because it is the same question. A
///   second threshold for it would drift away from the first one unnoticed.
/// * **The background does not count.** The region touching the image border
///   is the white *around* the motif; leaving it white is a choice, not an
///   unfinished picture. It gets no sparkle and stays out of [fraction].
/// * **Slivers under [kMinRegionPixels] are skipped**, see there.
CoverageReport regionCoverage({
  required Uint16List regionOf,
  required Uint8List rgba,
  required int width,
  required int height,
}) {
  final n = width * height;
  if (n == 0 || regionOf.length < n || rgba.length < n * 4) {
    return const CoverageReport(fraction: 0, empty: [], regions: 0);
  }

  // Region ids run 1..maxId in scan order, so plain lists index them.
  var maxId = 0;
  for (var i = 0; i < n; i++) {
    if (regionOf[i] > maxId) maxId = regionOf[i];
  }
  if (maxId == 0) {
    return const CoverageReport(fraction: 0, empty: [], regions: 0);
  }

  final total = Int32List(maxId + 1);
  final painted = Int32List(maxId + 1);
  final onBorder = Uint8List(maxId + 1);
  // Sums over the *unpainted* pixels, for the hint position.
  final sumX = Float64List(maxId + 1);
  final sumY = Float64List(maxId + 1);
  final bare = Int32List(maxId + 1);

  for (var y = 0; y < height; y++) {
    final row = y * width;
    for (var x = 0; x < width; x++) {
      final i = row + x;
      final id = regionOf[i];
      if (id == 0) continue; // outline
      total[id]++;
      if (x == 0 || y == 0 || x == width - 1 || y == height - 1) {
        onBorder[id] = 1;
      }
      if (rgba[i * 4 + 3] >= kWandMinAlpha) {
        painted[id]++;
      } else {
        bare[id]++;
        sumX[id] += x;
        sumY[id] += y;
      }
    }
  }

  var counted = 0;
  var totalPixels = 0;
  var paintedPixels = 0;
  final empty = <EmptyRegion>[];

  for (var id = 1; id <= maxId; id++) {
    if (total[id] < kMinRegionPixels || onBorder[id] == 1) continue;
    counted++;
    totalPixels += total[id];
    paintedPixels += painted[id];
    if (painted[id] / total[id] >= kRegionPainted) continue;
    final cx = sumX[id] / bare[id];
    final cy = sumY[id] / bare[id];
    final snapped = _snapToRegion(regionOf, width, height, id, cx, cy);
    empty.add(EmptyRegion(
      id: id,
      pixels: total[id],
      x: snapped.$1,
      y: snapped.$2,
    ));
  }

  empty.sort((a, b) => b.pixels.compareTo(a.pixels));
  return CoverageReport(
    fraction: totalPixels == 0 ? 0 : paintedPixels / totalPixels,
    empty: empty,
    regions: counted,
  );
}

/// Moves a centre of mass onto its own region.
///
/// A C-shaped area has its centroid in the notch — in a neighbouring region
/// or on the outline — and a sparkle there points at the wrong thing.
/// Searches outward in rings from the centroid and takes the first pixel
/// that belongs to [id]; for the common convex case that is the first look.
(double, double) _snapToRegion(
  Uint16List regionOf,
  int width,
  int height,
  int id,
  double cx,
  double cy,
) {
  final startX = cx.round().clamp(0, width - 1);
  final startY = cy.round().clamp(0, height - 1);
  if (regionOf[startY * width + startX] == id) return (cx, cy);

  final maxR = width > height ? width : height;
  for (var r = 1; r < maxR; r++) {
    for (var dy = -r; dy <= r; dy++) {
      final y = startY + dy;
      if (y < 0 || y >= height) continue;
      // Only the rim of the ring: everything inside was searched already.
      final step = (dy.abs() == r) ? 1 : 2 * r;
      for (var dx = -r; dx <= r; dx += step) {
        final x = startX + dx;
        if (x < 0 || x >= width) continue;
        if (regionOf[y * width + x] == id) {
          return (x.toDouble(), y.toDouble());
        }
      }
    }
  }
  return (cx, cy);
}
