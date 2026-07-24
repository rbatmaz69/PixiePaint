#!/usr/bin/env python3
"""Generates PixiePaint's background-music loops.

The loops are synthesised rather than licensed: gentle, seamless pieces that
can ship inside an offline app with no attribution question attached.

**Scope, honestly:** this file generates `music_box.wav`, the track added in
v7.6. `lullaby.wav` and `sunshine.wav` predate it and were made by a script
that was never kept — they are not reproducible from here, which is exactly
why this one is checked in. The next track is a function plus one line in
`TRACKS`, not a rediscovery.

    python3 tool/make_music.py            # writes every track defined here
    python3 tool/make_music.py music_box  # just one

Mono 16-bit at 22.05 kHz, matching the two tracks that were already there:
plenty for soft sine tones, and a third of the bytes of 44.1 kHz stereo in an
app that is downloaded by parents on a phone plan.

**Seamlessness matters more than the notes.** `Music` plays these with
`ReleaseMode.loop`, so any click at the wrap point is heard every few minutes
forever. Two rules keep it clean: every note must have decayed to silence
before the file ends, and the file length is a whole number of samples of the
bar grid.
"""
import math
import struct
import sys
import wave

RATE = 22050

# Note names to frequencies, one pentatonic-friendly octave and a bit. A
# pentatonic set has no semitone clashes, so any two notes sound fine
# together — which is what makes a generated piece listenable at all.
NOTES = {
    'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'G4': 392.00, 'A4': 440.00,
    'C5': 523.25, 'D5': 587.33, 'E5': 659.25, 'G5': 783.99, 'A5': 880.00,
    'C6': 1046.50,
}


def bell(freq, duration, amp=0.22, decay=4.5):
    """One soft bell-like note: a sine plus a quiet octave, exponential decay.

    The octave partial is what keeps a pure sine from sounding like a test
    tone. The decay is exponential rather than linear because that is how
    struck things actually fade, and the ear hears the difference.
    """
    out = []
    total = int(duration * RATE)
    for i in range(total):
        t = i / RATE
        env = math.exp(-decay * t)
        # A short attack, so the note starts rather than clicks.
        attack = min(1.0, t / 0.012)
        sample = math.sin(2 * math.pi * freq * t)
        sample += 0.3 * math.sin(4 * math.pi * freq * t)
        out.append(amp * env * attack * sample / 1.3)
    return out


def mix(buffer, notes, bar_seconds):
    """Adds (start_beat, note_name, duration_beats, amp) events into buffer."""
    for start, name, length, amp in notes:
        offset = int(start * bar_seconds * RATE)
        tone = bell(NOTES[name], length * bar_seconds, amp=amp)
        needed = offset + len(tone)
        if needed > len(buffer):
            buffer.extend([0.0] * (needed - len(buffer)))
        for i, sample in enumerate(tone):
            buffer[offset + i] += sample


def write(path, buffer):
    """Normalises softly and writes the WAV.

    The tail is checked rather than trusted: a loop that still has sound in
    its last samples clicks on every wrap, and that is the one defect nobody
    notices while making the file and everybody notices in the app.
    """
    peak = max(abs(s) for s in buffer) or 1.0
    # Deliberately not up to 1.0: this is background music under a child's
    # painting, and `Music` already plays it at volume 0.25.
    gain = 0.72 / peak
    tail = max(abs(s) for s in buffer[-int(0.05 * RATE):])
    assert tail * gain < 0.002, f'{path}: loop does not end in silence ({tail:.4f})'
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1.0, min(1.0, s * gain)) * 32767))
            for s in buffer))
    print(f'{path}: {len(buffer) / RATE:.2f} s')


def music_box():
    """"Spieluhr" — a slow music-box figure that turns around itself.

    Kept in a narrow range and on a long beat: it has to survive being heard
    for twenty minutes without ever asking for attention.
    """
    beat = 0.75
    melody = [
        'E5', 'G5', 'A5', 'G5', 'E5', 'D5', 'C5', 'D5',
        'E5', 'G5', 'C6', 'A5', 'G5', 'E5', 'D5', 'C5',
    ]
    events = []
    for i, name in enumerate(melody):
        events.append((i, name, 1.0, 0.20))
        # A quiet low note every other beat, the music-box "wind".
        if i % 4 == 0:
            events.append((i, 'C4' if (i // 4) % 2 == 0 else 'G4', 2.0, 0.12))
    # Two turns, so the piece is long enough not to feel like a ringtone.
    events += [(start + len(melody), name, length, amp)
               for start, name, length, amp in events]
    buffer = []
    mix(buffer, events, beat)
    # Room for the last note to fade out completely — see the tail assert.
    buffer.extend([0.0] * int(2.5 * RATE))
    return buffer


TRACKS = {'music_box': music_box}

if __name__ == '__main__':
    wanted = sys.argv[1:] or list(TRACKS)
    for name in wanted:
        write(f'assets/sounds/music/{name}.wav', TRACKS[name]())
