"""Generate gentle looping background tracks for Dripple.

Additive synthesis with soft envelopes. Written here rather than sourced so
the licensing is unambiguous and the loops are seamless by construction.
"""
import math, struct, wave

SR = 44100

def note(freq, dur, amp=0.25, harmonics=(1.0, 0.35, 0.12), attack=0.02, release=0.35):
    n = int(SR * dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        env = 1.0
        if t < attack:
            env = t / attack
        rel_start = dur - release
        if t > rel_start:
            env = max(0.0, (dur - t) / release)
        s = 0.0
        for k, h in enumerate(harmonics, start=1):
            s += h * math.sin(2 * math.pi * freq * k * t)
        out[i] = amp * env * s
    return out

def mix(buf, part, offset):
    for i, v in enumerate(part):
        j = offset + i
        if 0 <= j < len(buf):
            buf[j] += v

def pitch(semitones_from_a4):
    return 440.0 * (2 ** (semitones_from_a4 / 12))

# Scale degrees relative to A4, in semitones.
NOTES = {'C4': -9, 'D4': -7, 'E4': -5, 'F4': -4, 'G4': -2, 'A4': 0, 'B4': 2,
         'C5': 3, 'D5': 5, 'E5': 7, 'G5': 10, 'A5': 12,
         'C3': -21, 'F3': -16, 'G3': -14, 'A3': -12, 'E3': -17, 'D3': -19}

def render(bars, bpm, chords, melody, bass_amp=0.18, mel_amp=0.16):
    beat = 60.0 / bpm
    bar_len = beat * 4
    total = bar_len * bars
    buf = [0.0] * int(SR * total)

    # Chord pad: one sustained triad per bar.
    for b in range(bars):
        root = chords[b % len(chords)]
        for iv in (0, 4, 7):
            f = pitch(NOTES[root] + iv)
            mix(buf, note(f, bar_len, amp=bass_amp,
                          harmonics=(1.0, 0.18), attack=0.25,
                          release=bar_len * 0.5),
                int(b * bar_len * SR))

    # Melody: eighth-note arpeggio line.
    step = beat / 2
    for i, name in enumerate(melody * ((bars * 8) // len(melody) + 1)):
        start = i * step
        if start >= total:
            break
        if name is None:
            continue
        mix(buf, note(pitch(NOTES[name]), step * 1.6, amp=mel_amp,
                      harmonics=(1.0, 0.3, 0.1), attack=0.01,
                      release=step * 1.2),
            int(start * SR))

    # Seamless loop: crossfade the tail into the head.
    fade = int(SR * 0.5)
    for i in range(fade):
        w = i / fade
        buf[i] = buf[i] * w + buf[len(buf) - fade + i] * (1 - w)
    del buf[len(buf) - fade:]

    peak = max(abs(v) for v in buf) or 1.0
    scale = 0.85 / peak
    return [int(max(-32767, min(32767, v * scale * 32767))) for v in buf]

def write_wav(path, samples):
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', s) for s in samples))

TRACKS = {
    'menuTheme': dict(bars=8, bpm=76,
        chords=['C4', 'A3', 'F3', 'G3'],
        melody=['E5', 'G5', 'C5', 'E5', None, 'D5', 'C5', None]),
    'gamePlay': dict(bars=8, bpm=92,
        chords=['C4', 'F3', 'G3', 'C4'],
        melody=['C5', 'E5', 'G5', 'E5', 'D5', 'F4', 'A4', None]),
    'myTurn': dict(bars=8, bpm=112,
        chords=['G3', 'C4', 'D4', 'G3'],
        melody=['G5', 'E5', 'C5', 'E5', 'G5', 'A5', 'G5', None]),
    'tenseMoment': dict(bars=8, bpm=126,
        chords=['A3', 'F3', 'G3', 'E3'],
        melody=['A4', 'C5', 'E5', 'C5', 'B4', 'D5', 'A4', None]),
}

for name, cfg in TRACKS.items():
    write_wav(f'{name}.wav', render(**cfg))
    print(f'{name}.wav')
