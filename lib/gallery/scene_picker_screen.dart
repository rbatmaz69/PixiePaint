import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../canvas/canvas_screen.dart';
import '../l10n/l10n.dart';
import '../models/scene.dart';
import '../ui/app_theme.dart';
import '../ui/blob_background.dart';
import '../ui/bouncy.dart';
import '../ui/entrance.dart';
import '../ui/loading_pixie.dart';
import '../ui/pixie_header.dart';
import '../ui/pixie_palette.dart';
import '../ui/sticker.dart';

/// Picker for the ready-made sticker-book stages.
class ScenePickerScreen extends StatelessWidget {
  const ScenePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      body: BlobBackground(
        gradient: PixieGradients.pickerBg,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              PixieHeader(
                emoji: '🏞️',
                title: context.l10n.scenePickerTitle,
                accent: PixiePalette.mint,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: FutureBuilder<List<Scene>>(
                  future: Scene.loadAll(),
                  builder: (context, snapshot) {
                    final scenes = snapshot.data;
                    if (scenes == null) {
                      return const Center(child: LoadingPixie());
                    }
                    // Inside the loaded branch: the cascade starts when the
                    // stages are there, not while they load.
                    return EntranceGroup(
                        child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: scenes.length,
                      itemBuilder: (context, i) {
                        final scene = scenes[i];
                        return Entrance(
                          slot: i,
                          child: Bouncy(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => CanvasScreen(scene: scene)),
                          ),
                          child: StickerCard(
                            color: Colors.white,
                            radius: 24,
                            tiltIndex: i,
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: SvgPicture.asset(
                                        scene.assetPath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  scene.titleFor(lang),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        );
                      },
                    ));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
