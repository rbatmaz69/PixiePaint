import 'dart:typed_data';

// Pure edge detection — no dart:ui / Flutter imports so [detectEdges] can run
// in a background isolate via Isolate.run (same pattern as flood_fill.dart).

/// Detail presets for photo line art; a higher threshold keeps fewer edges.
enum LineArtDetail { bold, medium, fine }

int thresholdFor(LineArtDetail detail) => switch (detail) {
      LineArtDetail.bold => 96,
      LineArtDetail.medium => 64,
      LineArtDetail.fine => 44,
    };

/// Detects edges in a straight-RGBA image and returns a width*height mask
/// (255 = line pixel): grayscale → box blur → Sobel magnitude → threshold →
/// dilation. Border pixels are never edges.
Uint8List detectEdges({
  required Uint8List rgba,
  required int width,
  required int height,
  int blurPasses = 2,
  required int threshold,
  int dilatePasses = 2,
}) {
  final n = width * height;
  var gray = Uint8List(n);
  for (var i = 0; i < n; i++) {
    final o = i * 4;
    gray[i] = (rgba[o] * 77 + rgba[o + 1] * 151 + rgba[o + 2] * 28) >> 8;
  }
  for (var p = 0; p < blurPasses; p++) {
    gray = _boxBlur3(gray, width, height);
  }

  var mask = Uint8List(n);
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      final i = y * width + x;
      final tl = gray[i - width - 1], t = gray[i - width], tr = gray[i - width + 1];
      final l = gray[i - 1], r = gray[i + 1];
      final bl = gray[i + width - 1], b = gray[i + width], br = gray[i + width + 1];
      final gx = (tr + 2 * r + br) - (tl + 2 * l + bl);
      final gy = (bl + 2 * b + br) - (tl + 2 * t + tr);
      if (gx.abs() + gy.abs() >= threshold) mask[i] = 255;
    }
  }

  for (var p = 0; p < dilatePasses; p++) {
    mask = _dilate4(mask, width, height);
  }
  return mask;
}

/// Black pixels with the mask as alpha — ready for `decodeImageFromPixels`.
Uint8List maskToRgba(Uint8List mask, int width, int height) {
  final rgba = Uint8List(width * height * 4);
  for (var i = 0; i < mask.length; i++) {
    rgba[i * 4 + 3] = mask[i];
  }
  return rgba;
}

/// Separable 3x3 box blur with edge clamping.
Uint8List _boxBlur3(Uint8List src, int width, int height) {
  final tmp = Uint8List(src.length);
  for (var y = 0; y < height; y++) {
    final row = y * width;
    for (var x = 0; x < width; x++) {
      final l = src[row + (x > 0 ? x - 1 : 0)];
      final c = src[row + x];
      final r = src[row + (x < width - 1 ? x + 1 : width - 1)];
      tmp[row + x] = (l + c + r) ~/ 3;
    }
  }
  final out = Uint8List(src.length);
  for (var y = 0; y < height; y++) {
    final up = (y > 0 ? y - 1 : 0) * width;
    final row = y * width;
    final down = (y < height - 1 ? y + 1 : height - 1) * width;
    for (var x = 0; x < width; x++) {
      out[row + x] = (tmp[up + x] + tmp[row + x] + tmp[down + x]) ~/ 3;
    }
  }
  return out;
}

/// One 4-neighborhood dilation pass.
Uint8List _dilate4(Uint8List mask, int width, int height) {
  final out = Uint8List.fromList(mask);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = y * width + x;
      if (mask[i] != 0) continue;
      if ((x > 0 && mask[i - 1] != 0) ||
          (x < width - 1 && mask[i + 1] != 0) ||
          (y > 0 && mask[i - width] != 0) ||
          (y < height - 1 && mask[i + width] != 0)) {
        out[i] = 255;
      }
    }
  }
  return out;
}
