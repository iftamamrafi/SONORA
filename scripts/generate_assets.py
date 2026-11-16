#!/usr/bin/env python3
"""Generate SONORA's binary assets (app icons + sample tone) with pure stdlib.

GitHub file pushes via API handle text only, so these binaries are generated
on the build machine (GitHub Actions / Codemagic) before xcodebuild runs.
Running this locally is harmless: it overwrites the same files in place.
"""
import math, os, struct, wave, zlib

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
ICON_DIR = os.path.join(ROOT, "SONORA", "Resources", "Assets.xcassets", "AppIcon.appiconset")
WAV_PATH = os.path.join(ROOT, "SONORA", "Resources", "SampleTone.wav")

BG = (8, 8, 11)          # #08080B
ACCENT = (182, 156, 255) # #B69CFF
ACCENT2 = (139, 120, 216)# #8B78D8

def png_bytes(w, h, pixel_fn):
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filter: none
        for x in range(w):
            raw.extend(pixel_fn(x, y))
    def chunk(typ, data):
        c = struct.pack(">I", len(data)) + typ + data
        return c + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(bytes(raw), 6)) + chunk(b"IEND", b""))

def make_icon(size):
    # 7 vertical waveform bars centered, heights follow a sine envelope.
    bars = 7
    bar_w = size * 0.075
    gap = size * 0.035
    total_w = bars * bar_w + (bars - 1) * gap
    x0 = (size - total_w) / 2
    heights = [0.28, 0.52, 0.78, 1.0, 0.78, 0.52, 0.28]
    max_h = size * 0.52
    cy = size / 2
    def px(x, y):
        # subtle radial glow toward center
        dx = (x - size / 2) / size; dy = (y - size / 2) / size
        glow = max(0.0, 1.0 - math.sqrt(dx * dx + dy * dy) * 1.6) * 18
        base = (BG[0] + glow, BG[1] + glow, BG[2] + glow + 4)
        rel = x - x0
        if 0 <= rel < total_w:
            idx = int(rel // (bar_w + gap))
            off = rel - idx * (bar_w + gap)
            if off <= bar_w and 0 <= idx < bars:
                hh = heights[idx] * max_h
                if abs(y - cy) <= hh / 2:
                    t = idx / (bars - 1)
                    return tuple(int(ACCENT2[c] + (ACCENT[c] - ACCENT2[c]) * t) for c in range(3))
        return tuple(int(v) for v in base)
    path = os.path.join(ICON_DIR, f"AppIcon-{size}.png")
    with open(path, "wb") as f:
        f.write(png_bytes(size, size, px))
    print("wrote", path)

def make_wav():
    rate, dur = 44100, 3
    frames = bytearray()
    for i in range(rate * dur):
        t = i / rate
        freq = 440 + (880 - 440) * (t / dur)
        env = min(1.0, t * 4) * min(1.0, (dur - t) * 4)
        s = int(32767 * 0.35 * env * math.sin(2 * math.pi * freq * t))
        frames += struct.pack("<h", s)
    with wave.open(WAV_PATH, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
        w.writeframes(bytes(frames))
    print("wrote", WAV_PATH)

if __name__ == "__main__":
    os.makedirs(ICON_DIR, exist_ok=True)
    for s in (1024, 180, 120):
        make_icon(s)
    make_wav()
