"""Generates every sound effect and the ambient music for LAST EDGE by synthesis (free, ours;
PLAN.md section 18). Deterministic: the same script always writes the same files.

Usage (from the repo root):
    tools/art/.venv/bin/python tools/audio/generate_audio.py

Writes 16-bit WAVs to audio/sfx/ and audio/music/. Godot compresses them on import.
Sound names must match the SOUNDS list in autoload/audio.gd.
"""

import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SR = 44100
RNG = np.random.default_rng(7)


# --- Building blocks ------------------------------------------------------------------

def t(duration: float) -> np.ndarray:
    return np.arange(int(SR * duration)) / SR


def decay(duration: float, time_constant: float) -> np.ndarray:
    return np.exp(-t(duration) / time_constant)


def attack_decay(duration: float, attack: float, time_constant: float) -> np.ndarray:
    x = t(duration)
    return np.minimum(x / max(attack, 1e-4), 1.0) * np.exp(-np.maximum(x - attack, 0.0) / time_constant)


def noise(duration: float) -> np.ndarray:
    return RNG.uniform(-1.0, 1.0, int(SR * duration))


def sweep(f_start: float, f_end: float, duration: float, curve: float = 1.0) -> np.ndarray:
    """Instantaneous frequency gliding from f_start to f_end (exponential-ish)."""
    x = np.linspace(0.0, 1.0, int(SR * duration)) ** curve
    return f_start * (f_end / f_start) ** x


def osc(freq, duration: float, shape: str = "sine") -> np.ndarray:
    freq = np.broadcast_to(np.asarray(freq, dtype=float), (int(SR * duration),))
    phase = np.cumsum(freq) / SR
    if shape == "sine":
        return np.sin(2 * np.pi * phase)
    if shape == "square":
        return np.sign(np.sin(2 * np.pi * phase))
    if shape == "saw":
        return 2.0 * (phase % 1.0) - 1.0
    if shape == "tri":
        return 2.0 * np.abs(2.0 * (phase % 1.0) - 1.0) - 1.0
    raise ValueError(shape)


def lowpass(x: np.ndarray, cutoff) -> np.ndarray:
    """One-pole low-pass; cutoff may be an array (a sweeping filter)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    alpha = 1.0 - np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(x.size):
        acc += alpha[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x: np.ndarray, cutoff) -> np.ndarray:
    return x - lowpass(x, cutoff)


def bandpass(x: np.ndarray, low, high) -> np.ndarray:
    return lowpass(highpass(x, low), high)


def metal(freqs: list[float], duration: float, time_constant: float) -> np.ndarray:
    """Inharmonic partials ringing out: blades, clangs, chimes."""
    out = np.zeros(int(SR * duration))
    for i, f in enumerate(freqs):
        out += osc(f, duration) * decay(duration, time_constant / (1 + i * 0.35)) / (1 + i * 0.5)
    return out


def mix(*layers) -> np.ndarray:
    length = max(layer.size for layer in layers)
    out = np.zeros(length)
    for layer in layers:
        out[: layer.size] += layer
    return out


def crush(x: np.ndarray, steps: int = 12) -> np.ndarray:
    return np.round(x * steps) / steps


def normalize(x: np.ndarray, peak: float = 0.9) -> np.ndarray:
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def fade_edges(x: np.ndarray, fade_in: float = 0.002, fade_out: float = 0.01) -> np.ndarray:
    x = x.copy()
    a, b = int(SR * fade_in), int(SR * fade_out)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def write(path: Path, data: np.ndarray, stereo: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(data, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2 if stereo else 1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# --- Sound effects --------------------------------------------------------------------

def whoosh(duration: float, f_start: float, f_end: float, body: float = 0.0) -> np.ndarray:
    n = noise(duration)
    center = sweep(f_start, f_end, duration, 0.7)
    sound = bandpass(n, center * 0.5, center * 1.6) * attack_decay(duration, duration * 0.35, duration * 0.3)
    if body:
        sound += osc(sweep(f_start * 0.12, f_end * 0.05, duration), duration) * attack_decay(duration, duration * 0.3, duration * 0.25) * body
    return sound


def thump(duration: float, f_start: float, f_end: float, time_constant: float) -> np.ndarray:
    return osc(sweep(f_start, f_end, duration, 0.5), duration) * decay(duration, time_constant)


def crunch(duration: float, cutoff: float, time_constant: float) -> np.ndarray:
    return crush(lowpass(noise(duration), cutoff) * 3.0, 10) * decay(duration, time_constant)


def sfx() -> dict[str, np.ndarray]:
    s = {}
    s["slash_1"] = whoosh(0.2, 700, 3200, 0.25)
    s["slash_2"] = whoosh(0.19, 900, 3800, 0.2)
    s["slash_3"] = mix(whoosh(0.32, 450, 2600, 0.5), thump(0.25, 140, 50, 0.08) * 0.4)
    s["slash_air"] = whoosh(0.18, 1100, 4200, 0.1)
    s["dodge"] = highpass(whoosh(0.24, 1500, 600), 400) * 0.8
    s["jump"] = mix(whoosh(0.1, 900, 2000) * 0.5, thump(0.08, 220, 120, 0.03) * 0.4)
    s["land"] = mix(thump(0.14, 110, 45, 0.05), crunch(0.08, 1800, 0.02) * 0.4)
    s["hit_light"] = mix(thump(0.16, 160, 55, 0.05), crunch(0.12, 3200, 0.03) * 0.7,
                         metal([2600, 4100], 0.12, 0.03) * 0.2)
    s["hit_heavy"] = mix(thump(0.3, 120, 38, 0.1), crunch(0.2, 2400, 0.06) * 0.9,
                         metal([1900, 3100, 4700], 0.25, 0.06) * 0.25)
    s["execute"] = mix(thump(0.7, 90, 28, 0.22), crunch(0.4, 1800, 0.1),
                       metal([2400, 3700, 5600, 8200], 0.6, 0.15) * 0.45, whoosh(0.3, 3000, 600) * 0.5)
    s["parry"] = mix(metal([1850, 2780, 4130, 6050, 8900], 0.9, 0.22), thump(0.15, 260, 120, 0.04) * 0.6,
                     crunch(0.05, 6000, 0.01) * 0.6)
    s["guard"] = mix(metal([620, 980, 1530, 2400], 0.35, 0.08) * 0.8, thump(0.2, 130, 60, 0.06))
    s["deflect"] = mix(metal([3900, 5800, 8300], 0.4, 0.09), whoosh(0.15, 2500, 5000) * 0.4)
    s["draw_charge"] = osc(sweep(180, 420, 0.45), 0.45, "saw") * attack_decay(0.45, 0.3, 0.3) * 0.25 \
        + bandpass(noise(0.45), 2000, 6000) * attack_decay(0.45, 0.4, 0.2) * 0.3
    s["draw_strike"] = mix(metal([2200, 3300, 5100, 7600], 0.7, 0.16) * 0.8, whoosh(0.22, 4000, 900) * 0.8,
                           thump(0.2, 200, 70, 0.05) * 0.5)
    s["slam_dive"] = whoosh(0.3, 2500, 500, 0.3)
    s["slam_land"] = mix(thump(0.8, 85, 25, 0.25), crunch(0.5, 1200, 0.15), lowpass(noise(0.9), 300) * decay(0.9, 0.3) * 1.5)
    s["hurt"] = mix(thump(0.25, 180, 60, 0.07), crunch(0.18, 1400, 0.05) * 0.8,
                    osc(sweep(420, 180, 0.2), 0.2, "square") * decay(0.2, 0.06) * 0.15)
    s["death"] = mix(thump(1.0, 120, 30, 0.35), osc(sweep(500, 60, 0.9), 0.9, "tri") * decay(0.9, 0.35) * 0.4,
                     lowpass(noise(1.0), 500) * decay(1.0, 0.4) * 0.6)
    s["machine_death"] = mix(crunch(0.6, 2600, 0.14), thump(0.6, 100, 30, 0.18),
                             osc(sweep(900, 120, 0.4), 0.4, "square") * decay(0.4, 0.1) * 0.25,
                             lowpass(noise(0.7), 900) * decay(0.7, 0.2) * 0.8)
    s["laser"] = osc(sweep(1500, 420, 0.18) * (1 + 0.03 * osc(40, 0.18)), 0.18, "square") * attack_decay(0.18, 0.005, 0.07) * 0.5
    s["drone_charge"] = osc(sweep(380, 1300, 0.6), 0.6) * attack_decay(0.6, 0.5, 0.3) * (0.6 + 0.4 * osc(sweep(6, 30, 0.6), 0.6)) * 0.5
    s["hound_windup"] = osc(sweep(260, 820, 0.4), 0.4, "saw") * attack_decay(0.4, 0.3, 0.2) * (0.7 + 0.3 * osc(22, 0.4)) * 0.3
    s["linked_grab"] = mix(bandpass(noise(0.4), 300, 900) * attack_decay(0.4, 0.1, 0.15),
                           osc(sweep(140, 90, 0.4), 0.4, "saw") * decay(0.4, 0.15) * 0.3,
                           crush(osc(60, 0.4, "square"), 3) * decay(0.4, 0.1) * 0.08)
    s["cut_link"] = bandpass(noise(0.7), 1500, 6000) * crush(osc(sweep(1200, 90, 0.7), 0.7, "square"), 2).clip(0, 1) \
        * attack_decay(0.7, 0.05, 0.3) * 0.7
    s["freed"] = mix(metal([523.3], 1.0, 0.4), np.concatenate([np.zeros(int(SR * 0.09)), metal([659.3], 0.9, 0.35)]),
                     np.concatenate([np.zeros(int(SR * 0.18)), metal([784.0, 1568.0], 0.8, 0.35)])) * 0.5
    s["focus_on"] = mix(osc(sweep(700, 70, 0.7), 0.7) * decay(0.7, 0.3) * 0.6, lowpass(noise(0.7), sweep(3000, 200, 0.7)) * decay(0.7, 0.3))
    s["focus_off"] = mix(osc(sweep(70, 600, 0.45), 0.45) * attack_decay(0.45, 0.3, 0.2) * 0.5,
                         lowpass(noise(0.45), sweep(200, 3000, 0.45)) * attack_decay(0.45, 0.35, 0.15))
    s["rank_up"] = mix(*[np.concatenate([np.zeros(int(SR * 0.06 * i)), metal([f, f * 2.01], 0.5, 0.15)])
                         for i, f in enumerate([880.0, 1108.7, 1318.5])]) * 0.4
    s["ember_burst"] = mix(*[np.concatenate([np.zeros(int(SR * RNG.uniform(0, 0.25))), crunch(0.03, 5000, 0.008)])
                             for _ in range(9)]) * 0.5
    # Sounds added later restore the noise generator afterwards, so the loops below don't change.
    rng_state = RNG.bit_generator.state
    s["slice"] = mix(whoosh(0.22, 5200, 1400) * 0.6, metal([3100, 4700, 6900, 9300], 0.5, 0.1) * 0.6,
                     crunch(0.15, 4200, 0.04) * 0.7, bandpass(noise(0.5), 3000, 8000) * decay(0.5, 0.18) * 0.35)
    s["clank"] = mix(metal([410, 730, 1150, 1890], 0.3, 0.05) * 0.7, thump(0.15, 150, 60, 0.04))
    s["scrap_pop"] = mix(crunch(0.3, 3000, 0.07), thump(0.3, 140, 40, 0.08) * 0.6,
                         metal([1700, 2900], 0.2, 0.04) * 0.2)
    s["warden_roar"] = mix(osc(sweep(95, 60, 1.3) * (1 + 0.04 * osc(23, 1.3)), 1.3, "saw") * attack_decay(1.3, 0.15, 0.5),
                           lowpass(noise(1.3), sweep(1800, 300, 1.3)) * attack_decay(1.3, 0.1, 0.45) * 0.8,
                           crush(osc(sweep(190, 120, 1.3), 1.3, "square"), 4) * attack_decay(1.3, 0.2, 0.4) * 0.2)
    s["door_open"] = mix(metal([660, 990], 0.6, 0.18) * 0.5, osc(sweep(300, 900, 0.4), 0.4) * attack_decay(0.4, 0.05, 0.15) * 0.4,
                         bandpass(noise(0.4), 2000, 7000) * attack_decay(0.4, 0.02, 0.1) * 0.4)
    RNG.bit_generator.state = rng_state
    return {name: fade_edges(normalize(sound)) for name, sound in s.items()}


# --- Loops ----------------------------------------------------------------------------

def seamless(data: np.ndarray, loop_samples: int) -> np.ndarray:
    """Wraps everything past loop_samples back onto the start, so the loop has no seam."""
    out = data[:loop_samples].copy()
    tail = data[loop_samples:]
    out[: tail.shape[0]] += tail
    return out


def rain_loop(duration: float = 8.0) -> np.ndarray:
    total = duration + 1.0
    hiss = bandpass(noise(total), 1200, 7000) * 0.5
    patter = np.zeros(int(SR * total))
    for _ in range(int(160 * total)):
        start = RNG.integers(0, patter.size - 800)
        drop = bandpass(noise(0.015), 2500, 9000) * decay(0.015, 0.003) * RNG.uniform(0.2, 1.0)
        patter[start:start + drop.size] += drop
    rumble = lowpass(noise(total), 120) * 2.0
    loop = seamless(hiss + patter + rumble, int(SR * duration))
    left = loop
    right = np.roll(loop, int(SR * 0.37))
    return normalize(np.stack([left, right], axis=1).reshape(-1), 0.6)


def note_freq(name: str) -> float:
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + 12 * (octave - 4) - 9) / 12)


def music_loop() -> np.ndarray:
    """'Neon Rain': a moody ambient-combat loop, 80 BPM, 16 bars of Am – Fmaj7 – Dm – Em."""
    bpm = 80
    beat = 60.0 / bpm
    bars = 16
    loop_len = int(SR * beat * 4 * bars)
    total = loop_len + SR * 3
    left = np.zeros(total)
    right = np.zeros(total)
    chords = [["A2", "E3", "A3", "C4", "E4"], ["F2", "C3", "A3", "E4", "C4"],
              ["D2", "A2", "F3", "A3", "D4"], ["E2", "B2", "G3", "B3", "E4"]]

    def add(signal: np.ndarray, start_s: float, pan: float = 0.0, gain: float = 1.0) -> None:
        i = int(SR * start_s)
        end = min(i + signal.size, total)
        left[i:end] += signal[: end - i] * gain * (1 - max(pan, 0))
        right[i:end] += signal[: end - i] * gain * (1 + min(pan, 0))

    for bar in range(bars):
        chord = chords[bar % 4]
        start = bar * 4 * beat
        length = 4 * beat + 1.5
        # Pad: detuned saws, low-passed, slow swell.
        for k, n in enumerate(chord[1:]):
            f = note_freq(n)
            for detune, pan in ((0.997, -0.6), (1.003, 0.6)):
                voice = lowpass(osc(f * detune, length, "saw"), 900) * attack_decay(length, 1.2, 2.5)
                add(voice, start, pan, 0.06)
        # Bass: root on every beat, pulsing.
        root = note_freq(chord[0])
        for b in range(4):
            pulse = lowpass(osc(root, beat * 0.95, "saw"), 400) * attack_decay(beat * 0.95, 0.01, 0.25)
            add(pulse, start + b * beat, 0.0, 0.22)
        # Arpeggio from bar 5: plucked square, eighth notes, with an echo.
        if bar >= 4:
            tones = chord[2:] + [chord[3]]
            for e in range(8):
                f = note_freq(tones[e % len(tones)]) * 2
                pluck = lowpass(osc(f, 0.35, "square"), 2200) * decay(0.35, 0.08)
                at = start + e * beat / 2
                add(pluck, at, -0.3, 0.05)
                add(pluck, at + beat * 0.75, 0.4, 0.025)  # echo
        # Drums from bar 9: soft kick on 1 and 3, hats on the off-beats.
        if bar >= 8:
            for b in (0, 2):
                add(thump(0.35, 110, 42, 0.09), start + b * beat, 0.0, 0.35)
            for e in range(1, 8, 2):
                hat = highpass(noise(0.05), 7000) * decay(0.05, 0.012)
                add(hat, start + e * beat / 2, 0.2, 0.08)
    stereo = np.stack([seamless(left, loop_len), seamless(right, loop_len)], axis=1)
    return normalize(stereo, 0.8).reshape(-1)


def warden_loop() -> np.ndarray:
    """'Warden': the boss loop, 124 BPM, 8 bars of Dm – Bb – C – A, driving bass and drums."""
    bpm = 124
    beat = 60.0 / bpm
    bars = 8
    loop_len = int(SR * beat * 4 * bars)
    total = loop_len + SR * 2
    left = np.zeros(total)
    right = np.zeros(total)
    chords = [["D2", "A3", "D4", "F4"], ["A#1", "F3", "A#3", "D4"], ["C2", "G3", "C4", "E4"], ["A1", "E3", "A3", "C#4"]]

    def add(signal: np.ndarray, start_s: float, pan: float = 0.0, gain: float = 1.0) -> None:
        i = int(SR * start_s)
        end = min(i + signal.size, total)
        left[i:end] += signal[: end - i] * gain * (1 - max(pan, 0))
        right[i:end] += signal[: end - i] * gain * (1 + min(pan, 0))

    for bar in range(bars):
        chord = chords[(bar // 2) % 4]
        start = bar * 4 * beat
        root = note_freq(chord[0])
        for e in range(8):  # Driving eighth-note bass, octave jumps on the off-beats.
            f = root * (2 if e % 2 else 1)
            note = lowpass(osc(f, beat * 0.48, "saw"), 600) * attack_decay(beat * 0.48, 0.005, 0.12)
            add(note, start + e * beat / 2, 0.0, 0.28)
        length = 4 * beat
        for k, n in enumerate(chord[1:]):  # Dark stabs on 1 and the "and" of 2.
            for at in (0.0, 1.5):
                stab = crush(lowpass(osc(note_freq(n), beat * 0.6, "square"), 1400), 8) * decay(beat * 0.6, 0.12)
                add(stab, start + at * beat, -0.4 + 0.4 * k, 0.05)
        pad = lowpass(osc(note_freq(chord[1]) / 2, length + 1.0, "saw"), 500) * attack_decay(length + 1.0, 0.8, 2.0)
        add(pad, start, 0.0, 0.08)
        for b in range(4):  # Four-on-the-floor kick, snare on 2 and 4, sixteenth hats.
            add(thump(0.3, 130, 40, 0.07), start + b * beat, 0.0, 0.45)
            if b % 2:
                snare = mix(bandpass(noise(0.2), 1200, 6000) * decay(0.2, 0.06), thump(0.12, 220, 160, 0.04) * 0.5)
                add(snare, start + b * beat, 0.1, 0.22)
            for q in range(4):
                hat = highpass(noise(0.04), 8000) * decay(0.04, 0.01)
                add(hat, start + b * beat + q * beat / 4, 0.3, 0.05 if q % 2 else 0.08)
    stereo = np.stack([seamless(left, loop_len), seamless(right, loop_len)], axis=1)
    return normalize(stereo, 0.8).reshape(-1)


def main() -> None:
    for name, sound in sfx().items():
        write(ROOT / "audio" / "sfx" / f"{name}.wav", sound)
    write(ROOT / "audio" / "sfx" / "rain_loop.wav", rain_loop(), stereo=True)
    write(ROOT / "audio" / "music" / "neon_rain.wav", music_loop(), stereo=True)
    write(ROOT / "audio" / "music" / "warden.wav", warden_loop(), stereo=True)
    print("wrote", len(list((ROOT / "audio" / "sfx").glob("*.wav"))), "sound effects and 2 music loops")


if __name__ == "__main__":
    main()
