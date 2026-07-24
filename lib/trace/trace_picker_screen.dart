import 'package:flutter/material.dart';

import '../canvas/canvas_screen.dart';
import '../canvas/shape_renderer.dart';
import '../l10n/l10n.dart';
import '../models/tool.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/entrance.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';
import '../util/progress.dart';
import 'trace_template.dart';

/// Picker for tracing templates: ABC / 123 / shapes tabs, big glyph tiles.
/// Finished templates wear a little star badge.
class TracePickerScreen extends StatelessWidget {
  const TracePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letters = [
      for (final t in kTraceTemplates)
        if (t.kind == TraceKind.letter) t
    ];
    final numbers = [
      for (final t in kTraceTemplates)
        if (t.kind == TraceKind.number) t
    ];
    final shapes = [
      for (final t in kTraceTemplates)
        if (t.kind == TraceKind.shape) t
    ];
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: BlobBackground(
          gradient: PixieGradients.pickerBg,
          builder: (context, _) => SafeArea(
            child: Column(
              children: [
                PixieHeader(
                  emoji: '✍️',
                  title: context.l10n.traceTitle,
                  accent: PixiePalette.mint,
                  onBack: () => Navigator.of(context).pop(),
                ),
                TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: PixieTokens.softShadow(PixiePalette.mint),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(vertical: 6),
                  labelColor: scheme.primary,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  splashBorderRadius: BorderRadius.circular(24),
                  tabs: [
                    Tab(text: context.l10n.traceTabLetters),
                    Tab(text: context.l10n.traceTabNumbers),
                    Tab(text: context.l10n.traceTabShapes),
                  ],
                ),
                Expanded(
                  child: EntranceGroup(
                    child: ListenableBuilder(
                      listenable: Progress.instance,
                      builder: (context, _) => TabBarView(
                        children: [
                          _TraceGrid(templates: letters),
                          _TraceGrid(templates: numbers),
                          _TraceGrid(templates: shapes),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TraceGrid extends StatelessWidget {
  const _TraceGrid({required this.templates});

  final List<TraceTemplate> templates;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: templates.length,
      itemBuilder: (context, i) {
        final t = templates[i];
        final done = Progress.instance.completedTraceIds.contains(t.id);
        final Widget tile = Bouncy(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => CanvasScreen(traceTemplate: t)),
          ),
          child: StickerCard(
            color: Colors.white,
            radius: 22,
            tiltIndex: i,
            padding: EdgeInsets.zero,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (t.kind == TraceKind.shape)
                  CustomPaint(
                    size: const Size(64, 64),
                    painter: _ShapeGuidePainter(t.shape!),
                  )
                else
                  Text(
                    t.display,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w600,
                      fontSize: 52,
                      color: PixiePalette.ink,
                    ),
                  ),
                if (done)
                  const Positioned(
                    right: 8,
                    top: 8,
                    child: Text('⭐', style: TextStyle(fontSize: 18)),
                  ),
              ],
            ),
          ),
        );
        // Staggered entrance for the first visible tiles only — the grid is
        // 44 templates long and the rest arrive scrolled-to, not animated.
        return i < 12 ? Entrance(slot: i, child: tile) : tile;
      },
    );
  }
}

/// Small dotted preview of the shape template, matching the guide look.
class _ShapeGuidePainter extends CustomPainter {
  const _ShapeGuidePainter(this.kind);

  final ShapeKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ShapeRenderer.shapePath(
        kind, size.center(Offset.zero), size.shortestSide * 0.42);
    final paint = Paint()..color = PixiePalette.ink.withValues(alpha: 0.55);
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos != null) canvas.drawCircle(pos, 2.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ShapeGuidePainter old) => old.kind != kind;
}
