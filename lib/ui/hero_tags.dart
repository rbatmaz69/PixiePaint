/// Hero tags for the flights into the canvas.
///
/// Every way into the canvas — a coloring page, a saved picture, a scene —
/// starts from a tile that already shows the picture. These tags are what
/// makes that picture fly into the paper sheet instead of the screen simply
/// being replaced.
///
/// One place on purpose: a tag that matches on only one side of a flight is
/// silently no flight at all, and that is a hard bug to see. Prefixed by
/// kind so a page id and an artwork id can never collide.
library;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'pixie_palette.dart';

String pageHeroTag(String pageId) => 'page-$pageId';

String artworkHeroTag(String artworkId) => 'artwork-$artworkId';

String sceneHeroTag(String sceneId) => 'scene-$sceneId';

/// What the picture looks like *while* it is flying.
///
/// Both ends of every one of these flights put the image inside something
/// rounded — a white tile in the picker, a [PaperSheet] on the canvas — but
/// the [Hero] wraps only the image itself. So for the length of the flight
/// the picture lost its paper: a bare rectangle with square corners and no
/// shadow crossed the screen between two rounded things, which is the one
/// moment the sticker-book language dropped.
///
/// Flutter hands the flight the *destination* hero's child, which is what
/// we want either way — the two children are the same picture. All this
/// adds is the paper it sits on, held constant for the whole crossing.
/// Constant rather than lerped on purpose: both ends already agree on the
/// radius, so there is nothing to interpolate, and a shuttle that reads its
/// own direction is a well-known way to get a flight subtly wrong on the
/// way back.
///
/// Pass it to **both** heroes of a pair. Flutter prefers the destination's
/// builder, and "destination" swaps around on a pop.
Widget pixieHeroShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final Hero hero = toHeroContext.widget as Hero;
  final radius = BorderRadius.circular(PixieTokens.rTile);
  return DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: radius,
      boxShadow: PixieTokens.softShadow(PixiePalette.ink),
    ),
    child: ClipRRect(borderRadius: radius, child: hero.child),
  );
}
