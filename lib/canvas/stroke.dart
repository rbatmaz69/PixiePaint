import 'dart:ui';

import '../models/tool.dart';

class StrokePoint {
  final Offset pos;
  final double pressure; // normalized 0..1

  const StrokePoint(this.pos, this.pressure);
}

class Stroke {
  final ToolKind kind;
  final Color color;
  final double baseWidth;
  final int seed; // stable jitter seed for crayon rendering
  final List<StrokePoint> points = [];

  Stroke({
    required this.kind,
    required this.color,
    required this.baseWidth,
    required this.seed,
  });
}
