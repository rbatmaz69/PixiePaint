import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../ui/app_theme.dart';
import '../ui/bouncy.dart';
import '../ui/loading_pixie.dart';
import '../ui/soft_card.dart';
import '../util/sfx.dart';
import 'edge_detect.dart';
import 'photo_lineart.dart';

/// Preview between photo pick and canvas: shows the detected line art live
/// and lets the child pick a detail level before painting starts.
class PhotoLineArtScreen extends StatefulWidget {
  const PhotoLineArtScreen({super.key, required this.photoPath});

  final String photoPath;

  @override
  State<PhotoLineArtScreen> createState() => _PhotoLineArtScreenState();
}

class _PhotoLineArtScreenState extends State<PhotoLineArtScreen> {
  PhotoEdgeSource? _source;
  LineArtDetail _detail = LineArtDetail.medium;
  final Map<LineArtDetail, Uint8List> _masks = {};
  ui.Image? _preview;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final bytes = await File(widget.photoPath).readAsBytes();
    final source = await prepareEdgeSource(bytes);
    if (!mounted) return;
    _source = source;
    await _select(_detail);
  }

  Future<void> _select(LineArtDetail detail) async {
    final source = _source;
    if (source == null) return;
    setState(() => _detail = detail);
    final mask =
        _masks[detail] ?? (_masks[detail] = await detectMask(source, detail));
    if (!mounted || _detail != detail) return;
    final image = await maskToImage(mask, source.width, source.height);
    if (!mounted || _detail != detail) {
      image.dispose();
      return;
    }
    setState(() {
      _preview?.dispose();
      _preview = image;
    });
  }

  Future<void> _start() async {
    final source = _source;
    final mask = _masks[_detail];
    if (source == null || mask == null || _starting) return;
    setState(() => _starting = true);
    Sfx.instance.pop();
    final art = await maskToLineArt(mask, source.width, source.height,
        canvasWidth: kCanvasWidth, canvasHeight: kCanvasHeight);
    if (!mounted) {
      art.dispose();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CanvasScreen(photoLineArt: art)),
    );
  }

  @override
  void dispose() {
    _preview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: PixieGradients.photoBg),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '✨ ${context.l10n.lineArtTitle}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SoftCard(
                        color: Colors.white,
                        radius: 24,
                        shadowColor: Colors.black45,
                        width: 480,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            // Crossfade between detail levels instead of a
                            // hard swap (identical aspect, no layout jump).
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _preview == null
                                  ? const Center(
                                      key: ValueKey('loading'),
                                      child: LoadingPixie(emoji: '✨'))
                                  : RawImage(
                                      key: ValueKey(_preview),
                                      image: _preview,
                                      fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final (detail, label) in [
                            (LineArtDetail.bold, context.l10n.detailFew),
                            (LineArtDetail.medium, context.l10n.detailMedium),
                            (LineArtDetail.fine, context.l10n.detailMany),
                          ])
                            _DetailPill(
                              label: label,
                              selected: _detail == detail,
                              onTap: () => _select(detail),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Bouncy(
                        onTap: _masks[_detail] == null || _starting
                            ? null
                            : _start,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: PixieGradients.freeDraw,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: PixieTokens.softShadow(
                                const Color(0xFF7FDBDA)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: _starting
                                    ? const SizedBox(
                                        key: ValueKey('starting'),
                                        width: 26,
                                        height: 26,
                                        child: LoadingPixie(
                                            emoji: '✨', size: 20),
                                      )
                                    : const Icon(Icons.brush_rounded,
                                        key: ValueKey('idle'), size: 24),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                context.l10n.letsGo,
                                style:
                                    Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Bouncy(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Tooltip(
                      message: context.l10n.back,
                      child: Icon(Icons.arrow_back_rounded,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Bouncy(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: selected
              ? Border.all(color: scheme.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
