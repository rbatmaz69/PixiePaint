import 'dart:typed_data';
import 'dart:ui' show Offset;

/// Tracks how much of a trace guide the kid has covered. Pure logic on a
/// coarse cell grid — deliberately forgiving for 3-year-old motor skills:
/// a committed stroke point marks every guide cell within the brush radius.
class TraceCoverage {
  TraceCoverage._(this.cell, this.gridW, this.gridH, this.target)
      : visited = Uint8List(target.length) {
    var n = 0;
    for (final t in target) {
      if (t != 0) n++;
    }
    _targetCount = n;
  }

  final int cell;
  final int gridW;
  final int gridH;

  /// 1 where the guide has ink in that cell.
  final Uint8List target;
  final Uint8List visited;
  late final int _targetCount;
  int _visitedCount = 0;

  /// Builds the target grid from a guide's alpha channel (width*height
  /// bytes, one per pixel).
  factory TraceCoverage.fromAlpha(
    Uint8List alpha,
    int width,
    int height, {
    int cell = 32,
    int alphaThreshold = 32,
  }) {
    final gridW = (width + cell - 1) ~/ cell;
    final gridH = (height + cell - 1) ~/ cell;
    final target = Uint8List(gridW * gridH);
    for (var y = 0; y < height; y++) {
      final row = y * width;
      final cellRow = (y ~/ cell) * gridW;
      for (var x = 0; x < width; x++) {
        if (alpha[row + x] > alphaThreshold) {
          target[cellRow + x ~/ cell] = 1;
        }
      }
    }
    return TraceCoverage._(cell, gridW, gridH, target);
  }

  /// Marks every guide cell within [radius] of (x, y) as visited.
  void addPoint(double x, double y, double radius) {
    final minCx = ((x - radius) / cell).floor().clamp(0, gridW - 1);
    final maxCx = ((x + radius) / cell).floor().clamp(0, gridW - 1);
    final minCy = ((y - radius) / cell).floor().clamp(0, gridH - 1);
    final maxCy = ((y + radius) / cell).floor().clamp(0, gridH - 1);
    final r2 = (radius + cell / 2) * (radius + cell / 2);
    for (var cy = minCy; cy <= maxCy; cy++) {
      for (var cx = minCx; cx <= maxCx; cx++) {
        final i = cy * gridW + cx;
        if (target[i] == 0 || visited[i] != 0) continue;
        final dx = cx * cell + cell / 2 - x;
        final dy = cy * cell + cell / 2 - y;
        if (dx * dx + dy * dy > r2) continue;
        visited[i] = 1;
        _visitedCount++;
      }
    }
  }

  void addPoints(Iterable<Offset> points, double radius) {
    for (final p in points) {
      addPoint(p.dx, p.dy, radius);
    }
  }

  /// Fraction of guide cells covered so far, 0..1.
  double get fraction =>
      _targetCount == 0 ? 0 : _visitedCount / _targetCount;
}
