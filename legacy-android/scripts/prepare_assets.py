#!/usr/bin/env python3
"""Prepare Android 4-compatible launcher icons and offline focus tracks."""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parents[1] / "app" / "src" / "main" / "res" / "raw"
ICON = ROOT / "assets" / "parin_litner_icon.png"
SR = 22050
DURATION = 12
N = SR * DURATION
OUT.mkdir(parents=True, exist_ok=True)
random.seed(20260912)

def write_track(name, generator):
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for i in range(N):
            value = max(-1.0, min(1.0, generator(i / SR, i)))
            frames += struct.pack("<h", int(value * 23000))
        w.writeframes(frames)

def soft_env(t):
    phase = t % DURATION
    return min(1.0, phase / 1.8, (DURATION - phase) / 1.8)

def lofi(t, i):
    e = soft_env(t)
    slow = 0.5 + 0.5 * math.sin(2 * math.pi * t / 7.0)
    chord = (0.28 * math.sin(2 * math.pi * 174.61 * t)
             + 0.20 * math.sin(2 * math.pi * 261.63 * t)
             + 0.13 * math.sin(2 * math.pi * 329.63 * t))
    bell = 0.05 * math.sin(2 * math.pi * 523.25 * t) * (0.5 + 0.5 * math.sin(2 * math.pi * t / 4.0))
    return 0.42 * e * (0.72 + 0.28 * slow) * (chord + bell)

rain_state = 0.0
def rainy(t, i):
    global rain_state
    white = random.uniform(-1.0, 1.0)
    rain_state = 0.985 * rain_state + 0.015 * white
    texture = white - rain_state
    drone = 0.16 * math.sin(2 * math.pi * 98.0 * t) + 0.08 * math.sin(2 * math.pi * 147.0 * t)
    return 0.26 * texture + drone

def deep(t, i):
    pulse = 0.5 + 0.5 * math.sin(2 * math.pi * t / 8.0)
    drone = 0.30 * math.sin(2 * math.pi * 110.0 * t) + 0.16 * math.sin(2 * math.pi * 220.0 * t)
    pad = 0.08 * math.sin(2 * math.pi * 164.81 * t) * pulse
    return 0.62 * (0.75 + 0.25 * pulse) * (drone + pad)

write_track("lofi_night.wav", lofi)
write_track("rainy_focus.wav", rainy)
write_track("deep_focus.wav", deep)
print("Prepared three offline focus tracks in", OUT)

# Icon generation is done in CI only, to avoid committing generated binary files.
if not ICON.is_file():
    raise SystemExit("Expected app icon at " + str(ICON))
