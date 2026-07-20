import 'dart:math';

/// Rotation (radians) for a locked mystery tile at loop position [t]
/// (0..1): a brief double-wag occupying only [window] of each cycle, phase
/// shifted per [index] so tiles never wag in unison. Returns exactly 0
/// outside the wag window. Pure — unit-tested.
double lockedWiggleAngle(
  double t,
  int index, {
  double amplitude = 0.09,
  double window = 0.14,
}) {
  final phase = (t + index * 0.23) % 1.0;
  if (phase >= window) return 0;
  final local = phase / window;
  // Three half-swings, eased in and out by the sin envelope.
  return amplitude * sin(local * 3 * pi) * sin(local * pi);
}
