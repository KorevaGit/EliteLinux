#!/usr/bin/env python3
"""Готовит PNG для Plymouth и экрана входа из материалов branding/.

crown.png — корона, нарисованная заново по геометрии branding/crown.svg
           (сглаживание суперсэмплингом, золотой градиент как в SVG);
wordmark.png — надпись «ЭЛИТНЫЙ СОЧИ / НЕДВИЖИМОСТЬ ИНОГОРОДНИМ», вырезанная
           из 4K-обоев с логотипом как белая маска;
background.png — чистые обои, уменьшенные до 1920×1080;
bar.png, bar-track.png — заливки для полоски прогресса и поля ввода пароля;
login-bg.png — фон экрана входа: обои с короной и надписью над окном ввода.
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
BRANDING = ROOT / "branding"
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "theme/plymouth/elite"

# геометрия из crown.svg (viewBox 20 14 360 246, толщина линии 6)
CROWN = [(100, 210), (33, 70), (200, 168), (367, 70), (300, 210), (200, 28), (100, 210)]
DOOR = [(186, 245), (186, 204), (215, 204), (215, 245)]
BASE = [(95, 247), (305, 247)]
VB_X, VB_Y, VB_W, VB_H, STROKE = 20, 14, 360, 246, 6
GOLD = [(0.0, (0xe6, 0xc2, 0x7a)), (0.5, (0xc9, 0xa2, 0x5a)), (1.0, (0xa8, 0x7d, 0x38))]


def gold_at(t):
    for (t0, c0), (t1, c1) in zip(GOLD, GOLD[1:]):
        if t <= t1:
            k = (t - t0) / (t1 - t0)
            return tuple(round(a + (b - a) * k) for a, b in zip(c0, c1))
    return GOLD[-1][1]


def render_crown(width, ss=4):
    scale = width / VB_W * ss
    size = (round(VB_W * scale), round(VB_H * scale))
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    pt = lambda p: ((p[0] - VB_X) * scale, (p[1] - VB_Y) * scale)
    w = round(STROKE * scale)
    for poly in (CROWN, DOOR, BASE):
        d.line([pt(p) for p in poly], fill=255, width=w, joint="curve")
    # диагональный градиент (30,20) -> (370,255), как в SVG
    grad = Image.new("RGB", (64, 64))
    for y in range(64):
        for x in range(64):
            grad.putpixel((x, y), gold_at((x + y) / 126))
    grad = grad.resize(size, Image.BILINEAR)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    img.paste(grad, mask=mask)
    return img.resize((width, round(VB_H * width / VB_W)), Image.LANCZOS)


def extract_wordmark():
    src = Image.open(BRANDING / "wallpaper-logo.png").convert("RGB")
    box = (1330, 920, 2990, 1150)  # надпись справа от короны на 4K-обоях
    crop = src.crop(box)
    alpha = crop.convert("RGB").split()[0].point(lambda r: max(0, min(255, (r - 70) * 255 // 165)))
    bbox = alpha.point(lambda a: 255 if a > 40 else 0).getbbox()
    out = Image.new("RGBA", crop.size, (255, 255, 255, 0))
    out.putalpha(alpha)
    return out.crop(bbox)


OUT.mkdir(parents=True, exist_ok=True)
render_crown(360).save(OUT / "crown.png", optimize=True)
extract_wordmark().save(OUT / "wordmark.png", optimize=True)
Image.open(BRANDING / "wallpaper-clean.png").convert("RGB").resize((1920, 1080), Image.LANCZOS).save(OUT / "background.png", optimize=True)
# фон экрана входа: логотип по центру над окном ввода (окно — на 62% высоты)
bg = Image.open(BRANDING / "wallpaper-clean.png").convert("RGBA").resize((1920, 1080), Image.LANCZOS)
crown = render_crown(240)
bg.alpha_composite(crown, ((1920 - crown.width) // 2, 200))
word = extract_wordmark()
word = word.resize((620, round(word.height * 620 / word.width)), Image.LANCZOS)
bg.alpha_composite(word, ((1920 - word.width) // 2, 200 + crown.height + 34))
bg.convert("RGB").save(OUT / "login-bg.png", optimize=True)
Image.new("RGBA", (4, 4), (0xc9, 0xa2, 0x5a, 255)).save(OUT / "bar.png")
Image.new("RGBA", (4, 4), (255, 255, 255, 40)).save(OUT / "bar-track.png")
print("Готово:", OUT)
