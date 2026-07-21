import 'dart:typed_data';

/// Connected-component labeling over the line-art barrier — the foundation
/// of color-by-number: every enclosed area gets a stable region id.
///
/// Pure Dart (no dart:ui), safe for `Isolate.run`. Pixels with
/// `barrierAlpha > 128` are walls (same threshold as flood_fill.dart), so a
/// region here is exactly the area one flood fill would cover on a blank
/// layer. Returns one Uint16 region id per pixel; 0 = wall. Ids are
/// assigned in scan order, so they are deterministic for a given raster —
/// safe to persist across sessions.
Uint16List labelRegions(Uint8List barrierAlpha, int width, int height) {
  final regionOf = Uint16List(width * height);
  var nextId = 1;
  final stack = <int>[];
  for (var start = 0; start < regionOf.length; start++) {
    if (regionOf[start] != 0 || barrierAlpha[start] > 128) continue;
    final id = nextId++;
    // Span-based scanline fill, mirroring flood_fill.dart.
    stack.add(start);
    while (stack.isNotEmpty) {
      final idx = stack.removeLast();
      if (regionOf[idx] != 0 || barrierAlpha[idx] > 128) continue;
      final y = idx ~/ width;
      var x0 = idx % width;
      var x1 = x0;
      bool open(int i) => regionOf[i] == 0 && barrierAlpha[i] <= 128;
      while (x0 > 0 && open(y * width + x0 - 1)) {
        x0--;
      }
      while (x1 < width - 1 && open(y * width + x1 + 1)) {
        x1++;
      }
      for (var x = x0; x <= x1; x++) {
        regionOf[y * width + x] = id;
      }
      for (final ny in [y - 1, y + 1]) {
        if (ny < 0 || ny >= height) continue;
        var inSpan = false;
        for (var x = x0; x <= x1; x++) {
          final ni = ny * width + x;
          if (open(ni)) {
            if (!inSpan) {
              stack.add(ni);
              inSpan = true;
            }
          } else {
            inSpan = false;
          }
        }
      }
    }
    if (nextId >= 0xFFFF) break; // pathological input — stop labeling
  }
  return regionOf;
}
