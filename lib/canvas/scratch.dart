import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// The scratch picture: a sheet of colour under a black cover, revealed by
/// rubbing it away.
///
/// It fits the layers this app already has without bending any of them. The
/// colours go into the photo background, which the eraser has never been
/// able to touch; the cover is an ordinary paint layer; and the scratching
/// stick is the eraser doing exactly what it always does. Nothing here is a
/// new drawing mode — it is the same canvas, started differently.
///
/// Why it earns its place: it is the one way of drawing in the app where a
/// child cannot make a wrong mark. Whatever they rub, something beautiful
/// comes out, which is worth a great deal to a four-year-old who has just
/// discovered that lines can go wrong.

/// The bands under the cover, brightest at the top left.
///
/// Not from `PixiePalette`: this is what a child ends up drawing *with*,
/// which makes it content, like the paint colours and the rainbow pen.
const List<Color> kScratchColours = [
  Color(0xFFFF3B6B),
  Color(0xFFFF9B21),
  Color(0xFFFFD400),
  Color(0xFF37C86B),
  Color(0xFF20B7D8),
  Color(0xFF4A6BFF),
  Color(0xFFA34AFF),
  Color(0xFFFF4FA3),
];

/// The colour sheet, generated rather than shipped as an asset: it is a
/// gradient and some confetti, and 3 MB of PNG for that would be silly.
///
/// [seed] makes each picture its own — the bands run at a different angle
/// and the confetti lands elsewhere — while staying reproducible, which is
/// what lets a saved picture be redrawn identically if it ever has to be.
ui.Image scratchColourSheet(int width, int height, int seed) {
  final recorder = ui.PictureRecorder();
  final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  final canvas = Canvas(recorder, rect);
  final rng = Random(seed);

  // A diagonal sweep through every band, tilted a little per picture.
  final angle = -0.6 + rng.nextDouble() * 1.2;
  final direction = Offset(cos(angle), sin(angle));
  final reach = (rect.width + rect.height) / 2;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.center - direction * reach,
        rect.center + direction * reach,
        kScratchColours,
        // dart:ui only defaults the stops for a two-colour gradient; with
        // eight it wants them spelled out.
        [
          for (var i = 0; i < kScratchColours.length; i++)
            i / (kScratchColours.length - 1),
        ],
      ),
  );

  // Confetti, so a small scratch in a flat area still turns up something.
  for (var i = 0; i < 90; i++) {
    final p = Offset(rng.nextDouble() * width, rng.nextDouble() * height);
    canvas.drawCircle(
      p,
      width * (0.004 + rng.nextDouble() * 0.012),
      Paint()
        ..color = (rng.nextBool() ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
            .withValues(alpha: 0.10 + rng.nextDouble() * 0.18),
    );
  }

  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}

/// The cover over the colours. Not quite black — a warm-dark near-black
/// looks like a waxy layer rather than like the screen being off.
const Color kScratchCover = Color(0xFF15151A);

/// The covered sheet as the picture starts.
///
/// Deliberately one flat colour and nothing else. A waxy texture would look
/// better and would cost the one guarantee the op log makes: the cover is
/// written into the story as a plain fill in [kScratchCover] (see
/// `canvas_screen.dart`), and the time-lapse replays it as exactly that. A
/// cover that could not be described by an op would make the film start
/// with a page that never existed.
ui.Image scratchCover(int width, int height) {
  final recorder = ui.PictureRecorder();
  final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  Canvas(recorder, rect).drawRect(rect, Paint()..color = kScratchCover);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}
