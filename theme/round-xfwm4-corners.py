#!/usr/bin/env python3
"""Перерисовывает верхние углы рамки окон Xfwm4 с большим радиусом скругления.

Colloid даёт углы радиусом ~7 px; EliteLinux — мягче. Цвет пикселей берётся из
исходного XPM (символьные цвета active_color_2 / inactive_color_2 — их подставляет
Xfwm4 из GTK-темы). Использование: round-xfwm4-corners.py <каталог xfwm4> [радиус]
"""
import re
import sys
from pathlib import Path

xfwm = Path(sys.argv[1])
radius = int(sys.argv[2]) if len(sys.argv) > 2 else 12

for side in ("left", "right"):
    for state in ("active", "inactive"):
        src = xfwm / f"top-{side}-{state}.xpm"
        text = src.read_text()
        w, h, ncolors, _ = map(int, re.search(r'"(\d+) (\d+) (\d+) (\d+) ?"', text).groups())
        lines = re.findall(r'"([^"]*)"', text)
        colors = lines[1:1 + ncolors]
        fill = next(c[0] for c in colors if "None" not in c)
        width = max(w, radius)
        rows = []
        for y in range(h):
            row = ""
            for x in range(width):
                cx = x if side == "left" else width - 1 - x   # от внешнего края окна
                inside = True
                if y < radius and cx < radius:
                    dx, dy = radius - (cx + 0.5), radius - (y + 0.5)
                    inside = dx * dx + dy * dy <= radius * radius
                row += fill if inside else " "
            rows.append(row)
        name = f"top_{side}_{state}"
        out = [f'/* XPM */\nstatic char *{name}[] = {{', f'"{width} {h} {ncolors} 1 ",']
        out += [f'"{c}",' for c in colors]
        out += [f'"{r}",' for r in rows[:-1]] + [f'"{rows[-1]}"', "};"]
        src.write_text("\n".join(out) + "\n")
        # Xfwm4 предпочитает SVG/PNG перед XPM — убираем их, чтобы взялся новый угол
        for ext in ("svg", "png"):
            (xfwm / f"top-{side}-{state}.{ext}").unlink(missing_ok=True)

print(f"{xfwm}: углы окна — радиус {radius} px")
