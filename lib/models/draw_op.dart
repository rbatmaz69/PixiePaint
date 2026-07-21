import 'dart:convert';

import '../canvas/fill_pattern.dart';
import 'tool.dart';

/// Serializable drawing operations — the artwork's "story" for the
/// time-lapse replay. Pure Dart (no dart:ui) so encoding is unit-testable.
///
/// Forward compatibility: unknown op types are skipped on decode, unknown
/// tool/shape/pattern names fall back to safe defaults (brush/heart/solid),
/// so ops written by a newer app version never crash an older one.
sealed class DrawOp {
  const DrawOp();

  Map<String, dynamic> toJson();

  static DrawOp? fromJson(Map<String, dynamic> json) {
    switch (json['t']) {
      case 's':
        return StrokeOp(
          toolKind: _toolByName(json['k'] as String?),
          color: json['c'] as int? ?? 0xFF000000,
          baseWidth: (json['w'] as num?)?.toDouble() ?? 28,
          seed: json['sd'] as int? ?? 0,
          symmetryFolds: json['sy'] as int? ?? 1,
          points: [
            for (final v in (json['p'] as List? ?? const []))
              (v as num).toDouble()
          ],
        );
      case 'p':
        return StampOp(
          emoji: json['e'] as String?,
          imagePath: json['i'] as String?,
          x: (json['x'] as num?)?.toDouble() ?? 0,
          y: (json['y'] as num?)?.toDouble() ?? 0,
          size: (json['s'] as num?)?.toDouble() ?? 220,
          symmetryFolds: json['sy'] as int? ?? 1,
        );
      case 'h':
        return ShapeOp(
          kind: _shapeByName(json['k'] as String?),
          x: (json['x'] as num?)?.toDouble() ?? 0,
          y: (json['y'] as num?)?.toDouble() ?? 0,
          radius: (json['r'] as num?)?.toDouble() ?? 20,
          color: json['c'] as int? ?? 0xFF000000,
          strokeWidth: (json['w'] as num?)?.toDouble() ?? 11,
        );
      case 'f':
        return FillOp(
          x: (json['x'] as num?)?.toDouble() ?? 0,
          y: (json['y'] as num?)?.toDouble() ?? 0,
          color: json['c'] as int? ?? 0xFF000000,
          pattern: _patternByName(json['pt'] as String?),
        );
      case 'c':
        return const ClearOp();
    }
    return null;
  }

  static ToolKind _toolByName(String? name) =>
      ToolKind.values.asNameMap()[name] ?? ToolKind.brush;

  static ShapeKind _shapeByName(String? name) =>
      ShapeKind.values.asNameMap()[name] ?? ShapeKind.heart;

  static FillPattern _patternByName(String? name) =>
      FillPattern.values.asNameMap()[name] ?? FillPattern.solid;
}

double _round1(double v) => (v * 10).roundToDouble() / 10;
double _round2(double v) => (v * 100).roundToDouble() / 100;

class StrokeOp extends DrawOp {
  StrokeOp({
    required this.toolKind,
    required this.color,
    required this.baseWidth,
    required this.seed,
    required this.symmetryFolds,
    required this.points,
  });

  final ToolKind toolKind;
  final int color; // ARGB
  final double baseWidth;
  final int seed;
  final int symmetryFolds;

  /// Flat [x, y, pressure, x, y, pressure, …], coordinates rounded.
  final List<double> points;

  @override
  Map<String, dynamic> toJson() => {
        't': 's',
        'k': toolKind.name,
        'c': color,
        'w': _round1(baseWidth),
        'sd': seed,
        if (symmetryFolds != 1) 'sy': symmetryFolds,
        'p': [
          for (var i = 0; i < points.length; i += 3) ...[
            _round1(points[i]),
            _round1(points[i + 1]),
            _round2(points[i + 2]),
          ],
        ],
      };
}

class StampOp extends DrawOp {
  StampOp({
    this.emoji,
    this.imagePath,
    required this.x,
    required this.y,
    required this.size,
    required this.symmetryFolds,
  });

  /// Exactly one of [emoji] / [imagePath] is set; a deleted sticker file
  /// falls back to a star at replay time.
  final String? emoji;
  final String? imagePath;
  final double x, y, size;
  final int symmetryFolds;

  @override
  Map<String, dynamic> toJson() => {
        't': 'p',
        if (emoji != null) 'e': emoji,
        if (imagePath != null) 'i': imagePath,
        'x': _round1(x),
        'y': _round1(y),
        's': _round1(size),
        if (symmetryFolds != 1) 'sy': symmetryFolds,
      };
}

class ShapeOp extends DrawOp {
  ShapeOp({
    required this.kind,
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  final ShapeKind kind;
  final double x, y, radius;
  final int color;
  final double strokeWidth;

  @override
  Map<String, dynamic> toJson() => {
        't': 'h',
        'k': kind.name,
        'x': _round1(x),
        'y': _round1(y),
        'r': _round1(radius),
        'c': color,
        'w': _round1(strokeWidth),
      };
}

class FillOp extends DrawOp {
  FillOp({
    required this.x,
    required this.y,
    required this.color,
    required this.pattern,
  });

  final double x, y;
  final int color;
  final FillPattern pattern;

  @override
  Map<String, dynamic> toJson() => {
        't': 'f',
        'x': _round1(x),
        'y': _round1(y),
        'c': color,
        if (pattern != FillPattern.solid) 'pt': pattern.name,
      };
}

class ClearOp extends DrawOp {
  const ClearOp();

  @override
  Map<String, dynamic> toJson() => {'t': 'c'};
}

/// ops.json envelope.
String encodeOps(List<DrawOp> ops) =>
    jsonEncode({'v': 1, 'ops': [for (final op in ops) op.toJson()]});

List<DrawOp> decodeOps(String source) {
  try {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final ops = <DrawOp>[];
    for (final raw in (json['ops'] as List? ?? const [])) {
      final op = DrawOp.fromJson((raw as Map).cast<String, dynamic>());
      if (op != null) ops.add(op);
    }
    return ops;
  } catch (_) {
    return const [];
  }
}
