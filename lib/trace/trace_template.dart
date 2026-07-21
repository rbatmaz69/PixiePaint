import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../canvas/shape_renderer.dart';
import '../models/tool.dart';

/// Zero-asset tracing templates: letters and numbers come straight from the
/// bundled Fredoka font (hollow outline, worksheet style), shapes reuse the
/// shape tool's paths as dotted lines. Guides are regenerated from the id on
/// resume — nothing is persisted but the id.
enum TraceKind { letter, number, shape }

class TraceTemplate {
  final String id;
  final String display;
  final TraceKind kind;
  final ShapeKind? shape;

  const TraceTemplate({
    required this.id,
    required this.display,
    required this.kind,
    this.shape,
  });
}

final List<TraceTemplate> kTraceTemplates = [
  for (final c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ'.runes)
    TraceTemplate(
      id: 'letter_${String.fromCharCode(c)}',
      display: String.fromCharCode(c),
      kind: TraceKind.letter,
    ),
  for (final c in '0123456789'.runes)
    TraceTemplate(
      id: 'number_${String.fromCharCode(c)}',
      display: String.fromCharCode(c),
      kind: TraceKind.number,
    ),
  for (final s in ShapeKind.values)
    TraceTemplate(
      id: 'shape_${s.name}',
      display: s.name,
      kind: TraceKind.shape,
      shape: s,
    ),
];

TraceTemplate? traceTemplateById(String id) {
  for (final t in kTraceTemplates) {
    if (t.id == id) return t;
  }
  return null;
}

const Color _guideColor = Color(0x8C9AA5B1); // soft grey, ~55% alpha
const Color _startDotColor = Color(0xFF4CAF50);

/// Renders the guide for [template] as a full-canvas picture. Drawn by the
/// painter under the paint layer and never baked into commits or exports.
ui.Picture buildTraceGuide(TraceTemplate template, int width, int height) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
      recorder, ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  final center = ui.Offset(width / 2, height / 2);
  switch (template.kind) {
    case TraceKind.letter:
    case TraceKind.number:
      final tp = TextPainter(
        text: TextSpan(
          text: template.display,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: height * 0.72,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 10
              ..strokeJoin = StrokeJoin.round
              ..color = _guideColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final topLeft =
          center - ui.Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, topLeft);
      tp.dispose();
      // Green start dot near the glyph's top left — "start here".
      canvas.drawCircle(topLeft + ui.Offset(tp.width * 0.18, tp.height * 0.2),
          16, Paint()..color = _startDotColor);
    case TraceKind.shape:
      final path =
          ShapeRenderer.shapePath(template.shape!, center, height * 0.34);
      final dotPaint = Paint()..color = _guideColor;
      ui.Offset? start;
      // Paint has no dash support — walk the path metrics and drop dots.
      for (final metric in path.computeMetrics()) {
        for (double d = 0; d < metric.length; d += 30) {
          final pos = metric.getTangentForOffset(d)?.position;
          if (pos == null) continue;
          start ??= pos;
          canvas.drawCircle(pos, 8, dotPaint);
        }
      }
      if (start != null) {
        canvas.drawCircle(start, 16, Paint()..color = _startDotColor);
      }
  }
  return recorder.endRecording();
}
