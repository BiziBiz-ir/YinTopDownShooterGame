#!/usr/bin/env python3
"""Generates the game's retro/arcade SFX as 44.1kHz 16-bit mono WAVs.

Everything is synthesized here so there are no licensing questions and the
sounds stay consistent with each other. Re-run after tweaking:

    python3 tools/gen_sfx.py
"""

import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")


def timebase(dur):
    return np.arange(int(SR * dur)) / SR


def noise(n, seed=1):
    return np.random.default_rng(seed).uniform(-1.0, 1.0, n)


def oscillator(freqs, shape="square"):
    phase = 2.0 * np.pi * np.cumsum(freqs) / SR
    if shape == "square":
        return np.sign(np.sin(phase))
    if shape == "saw":
        return 2.0 * ((phase / (2.0 * np.pi)) % 1.0) - 1.0
    if shape == "tri":
        return 2.0 * np.abs(2.0 * ((phase / (2.0 * np.pi)) % 1.0) - 1.0) - 1.0
    return np.sin(phase)


def onepole_lp(x, cutoff_start, cutoff_end):
    """Sweeping one-pole lowpass. Loops in Python; short sounds only."""
    y = np.empty_like(x)
    z = 0.0
    n = len(x)
    for i in range(n):
        cutoff = cutoff_start + (cutoff_end - cutoff_start) * (i / max(n - 1, 1))
        a = 1.0 - np.exp(-2.0 * np.pi * cutoff / SR)
        z += a * (x[i] - z)
        y[i] = z
    return y


def crush(x, bits=8, hold=2):
    """Bit depth + sample-hold reduction for cheap early-90s grit."""
    levels = 2 ** (bits - 1)
    y = np.round(x * levels) / levels
    if hold > 1:
        y = np.repeat(y[::hold], hold)[: len(y)]
    return y


def fade_tail(x, seconds=0.01):
    n = min(int(SR * seconds), len(x))
    x[-n:] *= np.linspace(1.0, 0.0, n)
    return x


def save(name, x, peak=0.85, bits=10, hold=1):
    x = crush(x, bits, hold)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    data = (x * 32767.0).astype("<i2")
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data.tobytes())
    print(f"  {name:<16} {len(x) / SR:5.2f}s")


def handgun():
    t = timebase(0.14)
    body = oscillator(1200.0 * np.exp(-9.0 * t) + 380.0) * np.exp(-16.0 * t)
    click = onepole_lp(noise(len(t), 3), 7000.0, 4000.0) * np.exp(-90.0 * t) * 0.7
    return fade_tail(0.7 * body + 0.45 * click)


def pistol():
    t = timebase(0.32)
    body = oscillator(700.0 * np.exp(-6.0 * t) + 80.0) * np.exp(-8.0 * t)
    rumble = onepole_lp(noise(len(t), 5), 4200.0, 700.0) * np.exp(-9.0 * t) * 0.55
    sub = np.sin(2.0 * np.pi * np.cumsum(90.0 * np.exp(-4.0 * t) + 45.0) / SR) * np.exp(-5.0 * t)
    return fade_tail(0.75 * body + 0.4 * rumble + 0.5 * sub)


def smg():
    t = timebase(0.08)
    body = oscillator(1800.0 * np.exp(-11.0 * t) + 700.0) * np.exp(-26.0 * t)
    click = onepole_lp(noise(len(t), 7), 9000.0, 6000.0) * np.exp(-45.0 * t) * 0.6
    return fade_tail(0.7 * body + 0.5 * click, 0.006)


def rifle():
    t = timebase(0.22)
    body = oscillator(1000.0 * np.exp(-9.0 * t) + 220.0) * np.exp(-11.0 * t)
    crack = onepole_lp(noise(len(t), 11), 8000.0, 2000.0) * np.exp(-32.0 * t)
    ring = np.sin(2.0 * np.pi * 2300.0 * t) * np.exp(-14.0 * t) * 0.18
    return fade_tail(0.7 * body + 0.55 * crack + ring)


def shotgun():
    t = timebase(0.5)
    blast = onepole_lp(noise(len(t), 13), 9000.0, 380.0) * np.exp(-7.0 * t)
    thump = np.sin(2.0 * np.pi * np.cumsum(110.0 * np.exp(-5.0 * t) + 42.0) / SR) * np.exp(-4.5 * t)
    body = oscillator(230.0 * np.exp(-7.0 * t) + 55.0) * np.exp(-5.0 * t) * 0.35
    return fade_tail(0.85 * blast + 0.6 * thump + body)


def explosion():
    t = timebase(0.9)
    rumble = onepole_lp(noise(len(t), 17), 2200.0, 120.0) * np.exp(-4.5 * t)
    crack = onepole_lp(noise(len(t), 19), 9000.0, 5000.0) * np.exp(-45.0 * t)
    sub = np.sin(2.0 * np.pi * np.cumsum(95.0 * np.exp(-3.2 * t) + 26.0) / SR) * np.exp(-3.0 * t)
    return fade_tail(0.8 * rumble + 0.4 * crack + 0.7 * sub)


def hurt():
    t = timebase(0.2)
    body = oscillator(340.0 * np.exp(-7.0 * t) + 110.0) * np.exp(-10.0 * t)
    grit = onepole_lp(noise(len(t), 23), 5000.0, 1200.0) * np.exp(-18.0 * t) * 0.4
    return fade_tail(0.8 * body + grit)


def death():
    # Arcade game-over fall, doubles as the CRT power-down whine.
    t = timebase(1.2)
    fall = 760.0 * np.exp(-2.4 * t) + 55.0
    wobble = 1.0 + 0.035 * np.sin(2.0 * np.pi * 17.0 * t)
    body = oscillator(fall * wobble) * np.exp(-1.7 * t)
    whine = onepole_lp(noise(len(t), 29), 6000.0, 200.0) * np.exp(-3.5 * t) * 0.22
    return fade_tail(0.8 * body + whine, 0.25)


def select():
    t = timebase(0.07)
    blip = oscillator(np.full(len(t), 1400.0)) * np.exp(-32.0 * t)
    return fade_tail(blip, 0.006)


SOUNDS = {
    "handgun": (handgun, 0.8, 10, 2),
    "pistol": (pistol, 0.9, 9, 2),
    "smg": (smg, 0.75, 10, 2),
    "rifle": (rifle, 0.85, 10, 2),
    "shotgun": (shotgun, 0.92, 8, 3),
    "explosion": (explosion, 0.95, 8, 3),
    "hurt": (hurt, 0.7, 9, 2),
    "death": (death, 0.85, 8, 3),
    "select": (select, 0.55, 8, 2),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    print(f"writing to {os.path.normpath(OUT)}")
    for name, (fn, peak, bits, hold) in SOUNDS.items():
        save(f"{name}.wav", fn(), peak, bits, hold)
    print("done")


if __name__ == "__main__":
    main()
