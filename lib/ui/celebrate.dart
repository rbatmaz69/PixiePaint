import 'package:flutter/material.dart';

import '../util/sfx.dart';
import '../widgets/confetti_burst.dart';

/// How big a moment this is.
///
/// The app has two sizes of success and they should be told apart without
/// reading anything: a nod for "that worked", a party for "you finished
/// something".
enum Celebration {
  /// Shared, saved to photos, today's task ticked off.
  nod(ConfettiScale.small),

  /// A picture finished, a number-picture solved, a tracing completed.
  party(ConfettiScale.party);

  const Celebration(this.confetti);

  final ConfettiScale confetti;
}

/// The one way this app cheers.
///
/// Seven places used to assemble a celebration by hand out of [Sfx] and
/// [showConfetti], and they had drifted apart in the way hand-assembled
/// things do: sharing from the canvas threw the full 56-piece party while
/// sharing from the gallery gave the 18-piece nod, for the same act. Which
/// of the two is right is a design question with one answer; it just had no
/// single place to be answered in.
///
/// Reduce motion is handled where it always was, inside [showConfetti]: the
/// sound and the vibration stay, only the paper stops falling. That is the
/// app's rule — the reward stays, the movement goes — and routing every
/// celebration through here is what makes it true everywhere rather than
/// wherever someone remembered.
///
/// [sound] exists for the two share flows, where the "tada" is the answer to
/// passing the parental gate and has to play *before* the share sheet opens,
/// while the confetti belongs after it closes. There the sound is not part
/// of the celebration; it is the receipt for a tap.
void celebrate(
  BuildContext context, {
  Celebration level = Celebration.party,
  bool sound = true,
}) {
  if (sound) Sfx.instance.tada();
  showConfetti(context, scale: level.confetti);
}
