import 'tool.dart';

/// A piece of masking tape stuck on the paper.
///
/// Paint lands only inside it — or, with [inverted], only outside, which is
/// what real tape does: cover the bit that has to stay clean and paint over
/// the whole thing. Both are one motion for a child and neither needs any
/// precision, which is the point: staying inside a shape stops being a motor
/// skill and becomes a decision.
///
/// Pure data, like every other model here — the [ShapeKind] geometry it
/// turns into lives in `canvas/mask_path.dart`, so this file (and the op log
/// that carries it) stays free of dart:ui.
class Mask {
  const Mask({
    required this.kind,
    required this.x,
    required this.y,
    required this.radius,
    this.angle = 0,
    this.inverted = false,
  });

  final ShapeKind kind;
  final double x, y, radius;

  /// Only the strip reads it — the other motifs sit upright however the
  /// finger went, exactly as the shape tool draws them.
  final double angle;

  /// Paint outside the shape instead of inside it.
  final bool inverted;

  Mask copyWith({ShapeKind? kind, bool? inverted}) => Mask(
        kind: kind ?? this.kind,
        x: x,
        y: y,
        radius: radius,
        angle: angle,
        inverted: inverted ?? this.inverted,
      );

  Map<String, dynamic> toJson() => {
        'k': kind.name,
        'x': (x * 10).roundToDouble() / 10,
        'y': (y * 10).roundToDouble() / 10,
        'r': (radius * 10).roundToDouble() / 10,
        if (angle != 0) 'a': (angle * 1000).roundToDouble() / 1000,
        if (inverted) 'i': true,
      };

  /// Unknown shape names fall back to the circle, the way the op log's other
  /// enums fall back — a tape from a newer version must never crash a replay,
  /// and a round tape in the wrong place is a far smaller lie than no tape.
  static Mask? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = json.cast<String, dynamic>();
    return Mask(
      kind: ShapeKind.values.asNameMap()[map['k'] as String?] ??
          ShapeKind.circle,
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
      radius: (map['r'] as num?)?.toDouble() ?? 100,
      angle: (map['a'] as num?)?.toDouble() ?? 0,
      inverted: map['i'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Mask &&
      other.kind == kind &&
      other.x == x &&
      other.y == y &&
      other.radius == radius &&
      other.angle == angle &&
      other.inverted == inverted;

  @override
  int get hashCode => Object.hash(kind, x, y, radius, angle, inverted);
}

/// The motifs that can be tape. The rainbow is an open arc with no inside,
/// so it is not one of them; the line becomes a straight strip, which is the
/// most tape-like of the lot.
const List<ShapeKind> kTapeKinds = [
  ShapeKind.line,
  ShapeKind.circle,
  ShapeKind.square,
  ShapeKind.heart,
  ShapeKind.star,
  ShapeKind.triangle,
  ShapeKind.oval,
];
