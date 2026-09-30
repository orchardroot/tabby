#!/usr/bin/env python3
"""Render the Tabby boot animation and package it as a stored zip.

Canvas is a 768x256 band (the ROM's convention; bootanimation centres it on the
768x1024 screen over a black background). 30 fps.

part0  once   eyes open, blink, wordmark rises          (~2.0 s)
part1  loop   tabby stripe bar drifts under the wordmark (~1.0 s per loop)
part2  once   fade to black                             (~0.5 s)
"""
import math, os, shutil, sys, zipfile
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H, FPS = 768, 256, 30
BG = (11, 11, 12)
ORANGE = (217, 138, 58)
ORANGE_DARK = (150, 90, 35)
CREAM = (238, 232, 220)
FONT = "/System/Library/Fonts/Avenir Next.ttc"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build")

def font(size, index=0):
    for idx in (index, 0):
        try:
            return ImageFont.truetype(FONT, size, index=idx)
        except Exception:
            pass
    return ImageFont.load_default()

def ease(t):  # smoothstep
    t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)

def eye(draw, cx, cy, openness, glow):
    """One almond eye. openness 0..1, glow 0..1."""
    rw, rh = 44, 26 * openness
    if rh < 1:
        return
    col = tuple(int(c * (0.35 + 0.65 * glow)) for c in ORANGE)
    draw.ellipse([cx - rw, cy - rh, cx + rw, cy + rh], fill=col)
    # slit pupil
    pw, ph = 6, rh * 0.85
    draw.ellipse([cx - pw, cy - ph, cx + pw, cy + ph], fill=BG)
    # highlight
    draw.ellipse([cx - rw * 0.45, cy - rh * 0.55, cx - rw * 0.25, cy - rh * 0.25], fill=(255, 245, 225))

def wordmark(img, alpha, dy):
    f = font(104, index=8)  # Avenir Next Heavy
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    text = "Tabby"
    tw = d.textlength(text, font=f)
    x = (W - tw) / 2; y = 104 + dy
    d.text((x, y), text, font=f, fill=CREAM + (int(255 * alpha),))
    img.alpha_composite(layer)

def stripes(img, phase, alpha):
    """Tabby stripe bar: slanted orange bands drifting right, masked to a thin bar."""
    bar_y0, bar_y1 = 240, 248
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, x1 = 234, 534
    period = 34
    off = (phase * period) % period
    for i in range(-2, (x1 - x0) // period + 3):
        sx = x0 + i * period + off
        shade = ORANGE if i % 2 == 0 else ORANGE_DARK
        d.polygon([(sx, bar_y0), (sx + 18, bar_y0), (sx + 10, bar_y1), (sx - 8, bar_y1)], fill=shade + (int(255 * alpha),))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([x0, bar_y0, x1, bar_y1], radius=4, fill=255)
    layer.putalpha(Image.composite(layer.getchannel("A"), Image.new("L", img.size, 0), mask))
    img.alpha_composite(layer)

def frame():
    return Image.new("RGBA", (W, H), BG + (255,))

def save(img, part, n):
    d = os.path.join(OUT, part); os.makedirs(d, exist_ok=True)
    img.convert("RGB").save(os.path.join(d, f"{n:05d}.png"), optimize=True)

def part0():
    total = int(2.0 * FPS)
    for n in range(total):
        t = n / FPS
        img = frame(); d = ImageDraw.Draw(img)
        # eyes open 0.0-0.5s, blink 0.9-1.2s, glow up 0.0-0.6s
        if t < 0.5:
            o = ease(t / 0.5)
        elif 0.9 <= t < 1.05:
            o = 1 - ease((t - 0.9) / 0.15)
        elif 1.05 <= t < 1.2:
            o = ease((t - 1.05) / 0.15)
        else:
            o = 1.0
        g = ease(t / 0.6)
        for cx in (W / 2 - 70, W / 2 + 70):
            eye(d, cx, 56, o, g)
        # wordmark rises 1.2-1.8s
        if t >= 1.2:
            a = ease((t - 1.2) / 0.6); wordmark(img, a, (1 - a) * 26)
        if t >= 1.7:
            stripes(img, 0, ease((t - 1.7) / 0.3))
        save(img, "part0", n)

def part1():
    total = int(1.0 * FPS)
    for n in range(total):
        img = frame(); d = ImageDraw.Draw(img)
        for cx in (W / 2 - 70, W / 2 + 70):
            eye(d, cx, 56, 1.0, 1.0)
        wordmark(img, 1.0, 0)
        stripes(img, n / total, 1.0)
        save(img, "part1", n)

def part2():
    total = int(0.5 * FPS)
    for n in range(total):
        a = 1 - ease(n / (total - 1))
        img = frame(); d = ImageDraw.Draw(img)
        for cx in (W / 2 - 70, W / 2 + 70):
            eye(d, cx, 56, 1.0, a)
        wordmark(img, a, 0)
        stripes(img, 0.5, a)
        save(img, "part2", n)

def package():
    desc = f"{W} {H} {FPS}\nc 1 0 part0\nc 0 0 part1\nc 1 0 part2\n"
    with open(os.path.join(OUT, "desc.txt"), "w") as f:
        f.write(desc)
    zpath = os.path.join(OUT, "bootanimation.zip")
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_STORED) as z:
        z.write(os.path.join(OUT, "desc.txt"), "desc.txt")
        for part in ("part0", "part1", "part2"):
            for fn in sorted(os.listdir(os.path.join(OUT, part))):
                z.write(os.path.join(OUT, part, fn), f"{part}/{fn}")
    return zpath

if __name__ == "__main__":
    shutil.rmtree(OUT, ignore_errors=True); os.makedirs(OUT)
    part0(); part1(); part2()
    z = package()
    print(z, os.path.getsize(z), "bytes")
