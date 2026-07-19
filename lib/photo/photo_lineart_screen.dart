import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../canvas/canvas_screen.dart';
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
      backgroundColor: const Color(0xFFF3E5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✨ Ausmalbild zaubern',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: _preview == null
                            ? const Center(child: CircularProgressIndicator())
                            : RawImage(image: _preview, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final (detail, label) in const [
                          (LineArtDetail.bold, 'Wenig Details'),
                          (LineArtDetail.medium, 'Mittel'),
                          (LineArtDetail.fine, 'Viele Details'),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _detail == detail,
                            onSelected: (_) => _select(detail),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed:
                          _masks[_detail] == null || _starting ? null : _start,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      icon: _starting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5))
                          : const Icon(Icons.brush_rounded),
                      label: const Text('Los geht\'s!'),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filledTonal(
                iconSize: 28,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Zurück',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
