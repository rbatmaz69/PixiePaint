import 'dart:ui' as ui;

import '../canvas/stroke.dart';
import '../models/tool.dart';
import '../util/image_io.dart';
import 'trace_coverage.dart';
import 'trace_template.dart';

/// Tracks one tracing attempt: the guide picture, how much of it the kid
/// has covered, and whether the finish was already celebrated.
///
/// On resume the coverage restarts from zero (the strokes are baked into
/// the paint layer, not replayable), but a template that was finished in an
/// earlier session never celebrates twice — [celebrated] is seeded from the
/// stored progress.
class TraceSession {
  TraceSession._(this.template, this.guide, this._coverage, this.celebrated);

  /// Fraction of the guide that counts as "traced". Generous on purpose:
  /// three-year-olds do not follow lines precisely.
  static const double completionThreshold = 0.6;

  final TraceTemplate template;

  /// Ownership stays with the caller (the canvas controller disposes it).
  final ui.Picture guide;

  final TraceCoverage _coverage;
  bool celebrated;

  static Future<TraceSession?> create({
    required String templateId,
    required int width,
    required int height,
    required bool alreadyCompleted,
  }) async {
    final template = traceTemplateById(templateId);
    if (template == null) return null;
    final guide = buildTraceGuide(template, width, height);
    final image = await guide.toImage(width, height);
    final alpha = await alphaChannelOf(image);
    image.dispose();
    return TraceSession._(
      template,
      guide,
      TraceCoverage.fromAlpha(alpha, width, height),
      alreadyCompleted,
    );
  }

  double get fraction => _coverage.fraction;

  /// Feeds a committed stroke into the coverage grid. Returns true exactly
  /// once — on the stroke that finishes the template.
  bool registerStroke(Stroke stroke) {
    if (stroke.kind == ToolKind.eraser) return false;
    _coverage.addPoints(
      stroke.points.map((p) => p.pos),
      // At least half a chubby fingertip, so slow wobbly lines still count.
      stroke.baseWidth < 30 ? 30 : stroke.baseWidth,
    );
    if (celebrated || _coverage.fraction < completionThreshold) return false;
    celebrated = true;
    return true;
  }
}
