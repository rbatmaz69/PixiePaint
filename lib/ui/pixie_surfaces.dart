import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'pixie_palette.dart';

/// Everything the evening mode changes, and nothing else.
///
/// The rule this whole feature stands on: **the ground goes dark, the
/// stickers stay white, and the paper stays paper.** A sticker card, a
/// dialog, the tool bar and the sheet a child paints on are white in both
/// modes — they simply lie on dusk instead of on cream, which makes them
/// read more strongly, not less.
///
/// That is why this is a [ThemeExtension] with five gradients and two marks
/// rather than a second [ColorScheme]. Only the backdrop and the few things
/// printed straight onto it have an evening form; everything else already
/// has a ground of its own and needs no opinion from here.
@immutable
class PixieSurfaces extends ThemeExtension<PixieSurfaces> {
  const PixieSurfaces({
    required this.homeBg,
    required this.canvasBg,
    required this.pickerBg,
    required this.galleryBg,
    required this.photoBg,
    required this.onGround,
    required this.doodleAlpha,
    required this.blobAlpha,
  });

  final LinearGradient homeBg;
  final LinearGradient canvasBg;
  final LinearGradient pickerBg;
  final LinearGradient galleryBg;
  final LinearGradient photoBg;

  /// Text and marks lying directly on the backdrop: a screen heading, the
  /// "skip" link, a section title. Not the text *inside* a white card —
  /// that keeps its ink in both modes.
  final Color onGround;

  /// The scribbles behind the paper, and the drifting colour blobs. Both
  /// are quieter in the evening: a wash that reads as a whisper on cream
  /// reads as a stain on dusk.
  final double doodleAlpha;
  final double blobAlpha;

  /// Daytime — the values the app has always had, pointing at the existing
  /// gradients rather than restating them.
  static const PixieSurfaces day = PixieSurfaces(
    homeBg: PixieGradients.homeBg,
    canvasBg: PixieGradients.canvasBg,
    pickerBg: PixieGradients.pickerBg,
    galleryBg: PixieGradients.galleryBg,
    photoBg: PixieGradients.photoBg,
    onGround: PixiePalette.ink,
    doodleAlpha: 0.04,
    blobAlpha: 1.0,
  );

  static const PixieSurfaces dusk = PixieSurfaces(
    homeBg: _duskWarm,
    canvasBg: _duskViolet,
    pickerBg: _duskSun,
    galleryBg: _duskMint,
    photoBg: _duskPeach,
    onGround: PixiePalette.chalk,
    doodleAlpha: 0.06,
    // Bright blobs on a dark ground look like spills rather than light.
    blobAlpha: 0.45,
  );

  // Spelled out rather than built by a helper: a const constructor cannot
  // call one, and five near-identical constants are cheaper than making
  // this whole extension non-const.
  static const _duskWarm = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [PixiePalette.dusk, PixiePalette.duskWarm]);
  static const _duskViolet = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [PixiePalette.dusk, PixiePalette.duskViolet]);
  static const _duskSun = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [PixiePalette.dusk, PixiePalette.duskSun]);
  static const _duskMint = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [PixiePalette.dusk, PixiePalette.duskMint]);
  static const _duskPeach = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [PixiePalette.dusk, PixiePalette.duskPeach]);

  @override
  PixieSurfaces copyWith({
    LinearGradient? homeBg,
    LinearGradient? canvasBg,
    LinearGradient? pickerBg,
    LinearGradient? galleryBg,
    LinearGradient? photoBg,
    Color? onGround,
    double? doodleAlpha,
    double? blobAlpha,
  }) =>
      PixieSurfaces(
        homeBg: homeBg ?? this.homeBg,
        canvasBg: canvasBg ?? this.canvasBg,
        pickerBg: pickerBg ?? this.pickerBg,
        galleryBg: galleryBg ?? this.galleryBg,
        photoBg: photoBg ?? this.photoBg,
        onGround: onGround ?? this.onGround,
        doodleAlpha: doodleAlpha ?? this.doodleAlpha,
        blobAlpha: blobAlpha ?? this.blobAlpha,
      );

  @override
  PixieSurfaces lerp(PixieSurfaces? other, double t) {
    if (other == null) return this;
    LinearGradient g(LinearGradient a, LinearGradient b) =>
        LinearGradient.lerp(a, b, t) ?? b;
    return PixieSurfaces(
      homeBg: g(homeBg, other.homeBg),
      canvasBg: g(canvasBg, other.canvasBg),
      pickerBg: g(pickerBg, other.pickerBg),
      galleryBg: g(galleryBg, other.galleryBg),
      photoBg: g(photoBg, other.photoBg),
      onGround: Color.lerp(onGround, other.onGround, t) ?? other.onGround,
      doodleAlpha: doodleAlpha + (other.doodleAlpha - doodleAlpha) * t,
      blobAlpha: blobAlpha + (other.blobAlpha - blobAlpha) * t,
    );
  }
}

extension PixieSurfacesX on BuildContext {
  /// The backdrop for this screen.
  ///
  /// Falls back to [PixieSurfaces.day] rather than asserting. A bang here
  /// would take down every widget test that pumps a screen without the
  /// app's theme, and daytime is the honest default for a widget that has
  /// not been told otherwise.
  PixieSurfaces get surfaces =>
      Theme.of(this).extension<PixieSurfaces>() ?? PixieSurfaces.day;
}
