#!/usr/bin/env python3
"""Generates PixiePaint's drawing sound.

Companion to `make_music.py`, same format and the same reason for existing:
the asset is synthesised rather than licensed, so it can ship inside an
offline children's app with no attribution question attached — and, unlike
`pop.wav` and `tick.wav`, it is reproducible from a file that is checked in.

    python3 tool/make_sfx.py

Writes `assets/sounds/draw.wav`. Mono 16-bit at 22.05 kHz, matching the rest.

**What it has to sound like.** This one plays at the start of every stroke,
which on a busy picture is a few hundred times in a session. That rules out
anything with a pitch: a note repeated that often becomes a tune nobody
chose, and a wrong one. What is left is the sound of something soft touching
paper — filtered noise, very short, with no attack worth calling a click.

So: about 110 ms of noise, low-passed hard (a one-pole filter run twice),
with a fast rise and a long-ish fall. The rise is what keeps it from
clicking; the fall is what keeps it from sounding like a snare.
"""
import math
import random
import struct
import wave

RATE = 22050
OUT = 'assets/sounds/draw.wav'

DURATION = 0.11
# One-pole coefficient. Lower is duller; this lands somewhere around a
# pencil rather than a hiss.
CUTOFF = 0.12
# Deliberately quiet at the source as well as at the call site. A sound
# heard hundreds of times per session should sit under the music, not over
# it, and a parent who has turned the volume up for a video should not be
# startled by the next brush stroke.
PEAK = 0.22
RISE = 0.012


def envelope(t: float) -> float:
    """Fast rise, long fall — a touch, not a hit."""
    if t < RISE:
        return t / RISE
    fall = (t - RISE) / (DURATION - RISE)
    return math.exp(-4.0 * fall) * (1.0 - fall)


def main() -> None:
    # Fixed seed: the file is checked in, and a rebuild that produces a
    # different waveform every time is a diff nobody can review.
    rng = random.Random(1974)
    n = int(RATE * DURATION)
    y1 = 0.0
    y2 = 0.0
    frames = bytearray()
    for i in range(n):
        white = rng.uniform(-1.0, 1.0)
        # Two passes of the same one-pole low-pass: 12 dB/octave, which is
        # enough to take the fizz off without needing a real filter design.
        y1 += CUTOFF * (white - y1)
        y2 += CUTOFF * (y1 - y2)
        sample = y2 * envelope(i / RATE) * PEAK
        frames += struct.pack('<h', int(max(-1.0, min(1.0, sample)) * 32767))

    with wave.open(OUT, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))
    print(f'{OUT}: {n} frames, {len(frames)} bytes')


if __name__ == '__main__':
    main()
