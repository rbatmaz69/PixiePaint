import 'package:flutter/material.dart';

import '../canvas/canvas_controller.dart';
import '../l10n/l10n.dart';
import '../models/tool.dart';
import '../ui/bouncy.dart';
import '../ui/kid_sheet.dart';
import '../ui/pop_in.dart';
import '../util/color_utils.dart';
import '../util/sfx.dart';

const List<String> _presetEmojis = ['🐜', '🐈', '🐘'];

/// Bottom sheet with a big live preview dot, a fat continuous slider and
/// the three classic S/M/L presets as quick-tap shortcuts.
Future<void> showSizePicker(BuildContext context, CanvasController controller) {
  return showKidSheet<void>(
    context: context,
    emoji: '🐘',
    title: context.l10n.sizeTitle,
    child: _SizePickerBody(controller: controller),
  );
}

class _SizePickerBody extends StatefulWidget {
  const _SizePickerBody({required this.controller});

  final CanvasController controller;

  @override
  State<_SizePickerBody> createState() => _SizePickerBodyState();
}

class _SizePickerBodyState extends State<_SizePickerBody> {
  /// Bumped on preset taps so the preview dot pulses — deliberately not on
  /// slider drags (continuous retargeting would fight the pulse).
  int _presetTaps = 0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final light = needsBorder(controller.color);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live preview: the dot has the true on-canvas proportions.
              SizedBox(
                height: 110,
                child: Center(
                  child: Pulse(
                    trigger: _presetTaps,
                    peak: 1.12,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      width: controller.brushSize,
                      height: controller.brushSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: controller.color,
                        border: light
                            ? Border.all(color: Colors.black26, width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: (light ? Colors.black26 : controller.color)
                                .withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 16,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 26,
                  ),
                ),
                child: Slider(
                  min: kMinBrushSize,
                  max: kMaxBrushSize,
                  value: controller.brushSize.clamp(
                    kMinBrushSize,
                    kMaxBrushSize,
                  ),
                  onChanged: (v) => controller.selectSize(v, silent: true),
                  onChangeEnd: (_) => Sfx.instance.tick(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < kBrushSizes.length; i++)
                    Bouncy(
                      onTap: () {
                        setState(() => _presetTaps++);
                        controller.selectSize(kBrushSizes[i]);
                      },
                      playTick: false,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: controller.brushSize == kBrushSizes[i]
                              ? scheme.primary.withValues(alpha: 0.15)
                              : scheme.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _presetEmojis[i],
                          style: TextStyle(fontSize: 18.0 + i * 6),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
