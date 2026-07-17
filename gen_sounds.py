import math
import struct
import wave

SAMPLE_RATE = 44100


def note(freq, duration, amp=0.28, fade_ratio=0.35, start_phase=0.0):
    """Generate one sine-wave note as a list of float samples in [-1, 1],
    with a quick attack and an exponential-ish decay so it sounds like a
    soft bell/click rather than a harsh buzz."""
    n = int(SAMPLE_RATE * duration)
    samples = []
    attack = max(1, int(n * 0.06))
    for i in range(n):
        t = i / SAMPLE_RATE
        # Envelope: fast attack, smooth decay to silence.
        if i < attack:
            env = i / attack
        else:
            decay_pos = (i - attack) / max(1, (n - attack))
            env = (1 - decay_pos) ** 1.6
        value = amp * env * math.sin(2 * math.pi * freq * t + start_phase)
        samples.append(value)
    return samples


def silence(duration):
    return [0.0] * int(SAMPLE_RATE * duration)


def mix(*tracks):
    """Sum multiple same-length-ish tracks (pads shorter ones with silence)."""
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    peak = max(1.0, max(abs(v) for v in out))
    return [v / peak * 0.9 for v in out]


def write_wav(path, samples):
    frames = bytearray()
    for s in samples:
        s = max(-1.0, min(1.0, s))
        frames += struct.pack('<h', int(s * 32767))
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        f.writeframes(bytes(frames))


def concat(*tracks):
    out = []
    for t in tracks:
        out.extend(t)
    return out


# tap.wav — a very short, soft UI click (selection/navigation taps).
tap = note(1400, 0.05, amp=0.22)
write_wav('tap.wav', tap)

# success.wav — a bright two-note ascending chime (correct answer, stage complete).
success = concat(note(659.25, 0.11, amp=0.26), note(880.0, 0.16, amp=0.28))
write_wav('success.wav', success)

# error.wav — a short, gentle descending two-note "try again" tone (kept soft,
# not harsh, since this is an educational app for students).
error = concat(note(392.0, 0.10, amp=0.24), note(311.13, 0.16, amp=0.22))
write_wav('error.wav', error)

# complete.wav — a fuller three-note ascending fanfare for finishing an
# experiment / a whole quiz.
complete = concat(
    note(523.25, 0.11, amp=0.26),
    note(659.25, 0.11, amp=0.27),
    note(783.99, 0.24, amp=0.3),
)
write_wav('complete.wav', complete)

# measurement.wav — a crisp short "tick" for taking a reading (stopwatch,
# vernier caliper, meter needle settling).
measurement = note(1046.5, 0.045, amp=0.24)
write_wav('measurement.wav', measurement)

print('done')
