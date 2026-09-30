"""Real vector illustrations for flashcards, emitted as PDF operators.

These are actual educational visuals drawn with PDF path/fill operators —
not emoji, not stock images, and never containing words/text. The card
composer calls :func:`draw_art` to paint the visual area of each card.

Coordinate space: the caller passes the visual centre ``(cx, cy)`` in PDF
points and a ``size`` (roughly the width of the visual area). All drawing
is wrapped in ``q ... Q`` so graphics state never leaks.
"""
from __future__ import annotations

import math
from typing import Tuple

_K = 0.5523  # circle -> bezier constant


def parse_hex(hex_color: str) -> Tuple[float, float, float]:
    h = (hex_color or "#1B7A4D").lstrip("#")
    if len(h) != 6:
        h = "1B7A4D"
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))  # type: ignore[return-value]


def _f(c: Tuple[float, float, float]) -> str:
    return f"{c[0]:.3f} {c[1]:.3f} {c[2]:.3f} rg "


def _s(c: Tuple[float, float, float]) -> str:
    return f"{c[0]:.3f} {c[1]:.3f} {c[2]:.3f} RG "


def _circle(cx: float, cy: float, r: float, fill=None, stroke=None, lw: float = 2.0) -> str:
    k = _K * r
    s = f"{cx + r:.1f} {cy:.1f} m {cx + r:.1f} {cy + k:.1f} {cx + k:.1f} {cy + r:.1f} {cx:.1f} {cy + r:.1f} c "
    s += f"{cx - k:.1f} {cy + r:.1f} {cx - r:.1f} {cy + k:.1f} {cx - r:.1f} {cy:.1f} c "
    s += f"{cx - r:.1f} {cy - k:.1f} {cx - k:.1f} {cy - r:.1f} {cx:.1f} {cy - r:.1f} c "
    s += f"{cx + k:.1f} {cy - r:.1f} {cx + r:.1f} {cy - k:.1f} {cx + r:.1f} {cy:.1f} c h "
    op = ""
    if fill is not None and stroke is not None:
        op = _f(fill) + _s(stroke) + f"{lw:.1f} w B "
    elif fill is not None:
        op = _f(fill) + "f "
    else:
        op = _s(stroke or (0, 0, 0)) + f"{lw:.1f} w S "
    return op + s


def _ellipse(cx: float, cy: float, rx: float, ry: float, fill) -> str:
    s = f"q {rx:.1f} 0 0 {ry:.1f} {cx:.1f} {cy:.1f} cm "
    s += _circle(0, 0, 1.0, fill=fill)
    s += "Q "
    return s


def _rect(x: float, y: float, w: float, h: float, fill=None, stroke=None, lw: float = 2.0) -> str:
    op = f"{x:.1f} {y:.1f} {w:.1f} {h:.1f} re "
    if fill is not None and stroke is not None:
        return _f(fill) + _s(stroke) + f"{lw:.1f} w B " + op
    if fill is not None:
        return _f(fill) + op + "f "
    return _s(stroke or (0, 0, 0)) + f"{lw:.1f} w " + op + "S "


def _poly(points, fill=None, stroke=None, lw: float = 2.0, close: bool = True) -> str:
    s = ""
    for i, (x, y) in enumerate(points):
        s += f"{x:.1f} {y:.1f} {'m' if i == 0 else 'l'} "
    if close:
        s += "h "
    if fill is not None and stroke is not None:
        return _f(fill) + _s(stroke) + f"{lw:.1f} w " + s + "B "
    if fill is not None:
        return _f(fill) + s + "f "
    return _s(stroke or (0, 0, 0)) + f"{lw:.1f} w " + s + "S "


def _line(x1: float, y1: float, x2: float, y2: float, color, lw: float = 3.0) -> str:
    return _s(color) + f"{lw:.1f} w {x1:.1f} {y1:.1f} m {x2:.1f} {y2:.1f} l S "


def _leaf(cx: float, cy: float, s: float) -> str:
    green = (0.13, 0.55, 0.13)
    return _poly([(cx, cy + 0.16 * s), (cx + 0.16 * s, cy), (cx, cy - 0.16 * s), (cx - 0.16 * s, cy)], fill=green)


def _stem(cx: float, cy: float, s: float) -> str:
    return _line(cx, cy, cx + 0.02 * s, cy + 0.14 * s, (0.35, 0.2, 0.1), lw=4.0)


def _apple_shape(cx: float, cy: float, s: float) -> str:
    red = (0.85, 0.15, 0.15)
    out = _circle(cx - 0.09 * s, cy, 0.13 * s, fill=red)
    out += _circle(cx + 0.09 * s, cy, 0.13 * s, fill=red)
    out += _circle(cx, cy - 0.06 * s, 0.13 * s, fill=red)
    out += _stem(cx, cy + 0.12 * s, s)
    out += _leaf(cx + 0.10 * s, cy + 0.16 * s, s)
    return out


def draw_art(art: str, cx: float, cy: float, size: float, palette, extra=None) -> str:
    """Return PDF operators painting one illustration centred at (cx, cy)."""
    extra = extra or {}
    s = size
    pal = palette if isinstance(palette, tuple) else parse_hex(str(palette or "#1B7A4D"))
    o = "q "

    if art == "mango":
        o += _ellipse(cx, cy, 0.30 * s, 0.24 * s, (0.95, 0.55, 0.10))
        o += _ellipse(cx - 0.05 * s, cy + 0.03 * s, 0.20 * s, 0.15 * s, (1.0, 0.65, 0.20))
        o += _stem(cx + 0.10 * s, cy + 0.22 * s, s)
        o += _leaf(cx + 0.24 * s, cy + 0.30 * s, s)
    elif art == "banana":
        o += _poly([(cx - 0.30 * s, cy + 0.10 * s), (cx - 0.10 * s, cy - 0.12 * s),
                    (cx + 0.20 * s, cy - 0.10 * s), (cx + 0.30 * s, cy + 0.12 * s),
                    (cx + 0.05 * s, cy + 0.02 * s), (cx - 0.15 * s, cy + 0.16 * s)],
                   fill=(0.95, 0.80, 0.15))
        o += _circle(cx - 0.30 * s, cy + 0.10 * s, 0.03 * s, fill=(0.35, 0.2, 0.1))
    elif art == "apple":
        o += _apple_shape(cx, cy, s)
    elif art == "apples":
        n = max(1, min(10, int(extra.get("count", 1))))
        cols = 5 if n > 5 else n
        gw = 0.34 * s
        x0 = cx - (cols - 1) * gw / 2
        for i in range(n):
            row, col = divmod(i, 5 if n > 5 else n)
            o += _apple_shape(x0 + col * gw, cy + (0.20 * s if row == 0 else -0.22 * s), s * 0.55)
    elif art == "orange":
        o += _circle(cx, cy, 0.26 * s, fill=(1.0, 0.55, 0.05))
        o += _circle(cx - 0.07 * s, cy + 0.07 * s, 0.08 * s, fill=(1.0, 0.68, 0.25))
        o += _leaf(cx + 0.05 * s, cy + 0.30 * s, s)
    elif art in ("guava", "papaya"):
        o += _ellipse(cx, cy, 0.24 * s, 0.30 * s, (0.45, 0.70, 0.25))
        o += _ellipse(cx, cy, 0.14 * s, 0.18 * s, (0.60, 0.80, 0.40))
        o += _leaf(cx + 0.08 * s, cy + 0.32 * s, s)
    elif art == "grapes":
        purple = (0.45, 0.20, 0.55)
        for dx, dy in [(-0.12, 0.10), (0.0, 0.12), (0.12, 0.10),
                       (-0.06, -0.04), (0.06, -0.04), (0.0, -0.18)]:
            o += _circle(cx + dx * s, cy + dy * s, 0.08 * s, fill=purple)
        o += _stem(cx, cy + 0.20 * s, s)
        o += _leaf(cx + 0.12 * s, cy + 0.26 * s, s)
    elif art in ("cow", "goat", "dog", "buffalo"):
        body = {"cow": (0.95, 0.93, 0.88), "goat": (0.75, 0.75, 0.78),
                "dog": (0.72, 0.48, 0.28), "buffalo": (0.25, 0.25, 0.28)}[art]
        dark = (0.20, 0.12, 0.08)
        o += _ellipse(cx, cy + 0.02 * s, 0.30 * s, 0.18 * s, body)
        if art == "cow":
            o += _circle(cx - 0.10 * s, cy + 0.05 * s, 0.06 * s, fill=dark)
            o += _circle(cx + 0.12 * s, cy - 0.05 * s, 0.05 * s, fill=dark)
        o += _circle(cx + 0.32 * s, cy + 0.14 * s, 0.11 * s, fill=body)
        o += _circle(cx + 0.35 * s, cy + 0.15 * s, 0.02 * s, fill=dark)  # eye
        if art in ("cow", "goat", "buffalo"):
            o += _line(cx + 0.28 * s, cy + 0.24 * s, cx + 0.24 * s, cy + 0.32 * s, dark, lw=3.0)
            o += _line(cx + 0.36 * s, cy + 0.24 * s, cx + 0.40 * s, cy + 0.32 * s, dark, lw=3.0)
        else:
            o += _poly([(cx + 0.26 * s, cy + 0.20 * s), (cx + 0.30 * s, cy + 0.30 * s),
                        (cx + 0.34 * s, cy + 0.20 * s)], fill=body)  # ear
        for dx in (-0.20, -0.08, 0.08, 0.20):
            o += _rect(cx + dx * s - 0.03 * s, cy - 0.34 * s, 0.06 * s, 0.20 * s, fill=dark)
        o += _line(cx - 0.30 * s, cy + 0.10 * s, cx - 0.36 * s, cy - 0.12 * s, dark, lw=3.0)  # tail
    elif art in ("hen", "bird", "parrot", "crow", "sparrow", "pigeon", "owl", "peacock"):
        blue = (0.20, 0.45, 0.80)
        o += _ellipse(cx - 0.02 * s, cy - 0.02 * s, 0.24 * s, 0.16 * s, blue)
        o += _circle(cx + 0.20 * s, cy + 0.10 * s, 0.10 * s, fill=blue)
        o += _poly([(cx + 0.29 * s, cy + 0.10 * s), (cx + 0.37 * s, cy + 0.07 * s),
                    (cx + 0.29 * s, cy + 0.04 * s)], fill=(1.0, 0.65, 0.10))  # beak
        o += _circle(cx + 0.22 * s, cy + 0.13 * s, 0.02 * s, fill=(0, 0, 0))  # eye
        o += _poly([(cx - 0.26 * s, cy), (cx - 0.36 * s, cy + 0.10 * s),
                    (cx - 0.26 * s, cy + 0.06 * s)], fill=(0.15, 0.35, 0.65))  # tail
        o += _line(cx - 0.05 * s, cy - 0.17 * s, cx - 0.05 * s, cy - 0.28 * s, (1.0, 0.65, 0.10), lw=3.0)
        o += _line(cx + 0.05 * s, cy - 0.17 * s, cx + 0.05 * s, cy - 0.28 * s, (1.0, 0.65, 0.10), lw=3.0)
    elif art == "fish":
        o += _ellipse(cx, cy, 0.26 * s, 0.14 * s, (0.25, 0.55, 0.90))
        o += _poly([(cx - 0.24 * s, cy), (cx - 0.38 * s, cy + 0.12 * s),
                    (cx - 0.38 * s, cy - 0.12 * s)], fill=(0.20, 0.45, 0.80))
        o += _circle(cx + 0.15 * s, cy + 0.03 * s, 0.025 * s, fill=(0, 0, 0))
        o += _poly([(cx, cy + 0.12 * s), (cx + 0.08 * s, cy + 0.20 * s),
                    (cx + 0.12 * s, cy + 0.10 * s)], fill=(0.20, 0.45, 0.80))
    elif art == "book":
        o += _poly([(cx - 0.26 * s, cy - 0.16 * s), (cx + 0.26 * s, cy - 0.16 * s),
                    (cx + 0.26 * s, cy + 0.16 * s), (cx - 0.26 * s, cy + 0.16 * s)],
                   fill=(0.15, 0.35, 0.70))
        o += _poly([(cx - 0.20 * s, cy - 0.12 * s), (cx + 0.02 * s, cy - 0.12 * s),
                    (cx + 0.02 * s, cy + 0.12 * s), (cx - 0.20 * s, cy + 0.12 * s)],
                   fill=(1, 1, 1))
        o += _poly([(cx + 0.06 * s, cy - 0.12 * s), (cx + 0.22 * s, cy - 0.12 * s),
                    (cx + 0.22 * s, cy + 0.12 * s), (cx + 0.06 * s, cy + 0.12 * s)],
                   fill=(0.95, 0.95, 0.95))
    elif art == "ball":
        o += _circle(cx, cy, 0.26 * s, fill=(1, 1, 1), stroke=(0.15, 0.15, 0.15), lw=3.0)
        o += _poly([(cx, cy + 0.08 * s), (cx + 0.07 * s, cy + 0.03 * s), (cx + 0.04 * s, cy - 0.06 * s),
                    (cx - 0.04 * s, cy - 0.06 * s), (cx - 0.07 * s, cy + 0.03 * s)], fill=(0.15, 0.15, 0.15))
        for dx, dy in [(-0.14, 0.10), (0.14, 0.10), (0.0, -0.16)]:
            o += _circle(cx + dx * s, cy + dy * s, 0.045 * s, fill=(0.15, 0.15, 0.15))
    elif art == "sun":
        o += _circle(cx, cy, 0.18 * s, fill=(1.0, 0.80, 0.10))
        for i in range(8):
            a = math.pi * i / 4
            o += _line(cx + 0.24 * s * math.cos(a), cy + 0.24 * s * math.sin(a),
                       cx + 0.34 * s * math.cos(a), cy + 0.34 * s * math.sin(a),
                       (1.0, 0.65, 0.10), lw=4.0)
    elif art == "moon":
        o += _circle(cx, cy, 0.24 * s, fill=(1.0, 0.85, 0.30))
        o += _circle(cx + 0.12 * s, cy + 0.08 * s, 0.20 * s, fill=(1, 1, 1))
    elif art == "tree":
        o += _rect(cx - 0.04 * s, cy - 0.34 * s, 0.08 * s, 0.24 * s, fill=(0.45, 0.28, 0.12))
        o += _circle(cx, cy + 0.10 * s, 0.20 * s, fill=(0.15, 0.50, 0.20))
        o += _circle(cx - 0.12 * s, cy + 0.02 * s, 0.13 * s, fill=(0.20, 0.58, 0.25))
        o += _circle(cx + 0.12 * s, cy + 0.02 * s, 0.13 * s, fill=(0.20, 0.58, 0.25))
    elif art == "flower":
        for i in range(5):
            a = 2 * math.pi * i / 5 - math.pi / 2
            o += _circle(cx + 0.13 * s * math.cos(a), cy + 0.13 * s * math.sin(a),
                         0.09 * s, fill=(0.95, 0.45, 0.60))
        o += _circle(cx, cy, 0.08 * s, fill=(1.0, 0.80, 0.10))
        o += _rect(cx - 0.015 * s, cy - 0.34 * s, 0.03 * s, 0.20 * s, fill=(0.15, 0.50, 0.20))
    elif art == "eye":
        o += _ellipse(cx, cy, 0.30 * s, 0.16 * s, (0.92, 0.93, 0.95))
        o += _circle(cx, cy, 0.09 * s, fill=(0.30, 0.45, 0.70))
        o += _circle(cx, cy, 0.045 * s, fill=(0, 0, 0))
        o += _circle(cx + 0.03 * s, cy + 0.03 * s, 0.015 * s, fill=(1, 1, 1))
    elif art == "hand":
        skin = (0.95, 0.75, 0.55)
        o += _ellipse(cx, cy - 0.05 * s, 0.14 * s, 0.16 * s, skin)
        for i, dx in enumerate([-0.105, -0.035, 0.035, 0.105]):
            o += _rect(cx + dx * s - 0.03 * s, cy + 0.02 * s, 0.06 * s, 0.16 * s, fill=skin)
        o += _ellipse(cx - 0.17 * s, cy - 0.02 * s, 0.05 * s, 0.09 * s, skin)
    elif art == "running":
        ink = (0.10, 0.25, 0.55)
        o += _circle(cx + 0.05 * s, cy + 0.28 * s, 0.07 * s, fill=ink)
        o += _line(cx, cy + 0.18 * s, cx - 0.05 * s, cy - 0.08 * s, ink, lw=6.0)
        o += _line(cx - 0.03 * s, cy + 0.10 * s, cx - 0.25 * s, cy + 0.16 * s, ink, lw=5.0)
        o += _line(cx - 0.03 * s, cy + 0.10 * s, cx + 0.16 * s, cy - 0.02 * s, ink, lw=5.0)
        o += _line(cx - 0.05 * s, cy - 0.08 * s, cx - 0.22 * s, cy - 0.28 * s, ink, lw=5.0)
        o += _line(cx - 0.05 * s, cy - 0.08 * s, cx + 0.14 * s, cy - 0.24 * s, ink, lw=5.0)
        o += _line(cx - 0.34 * s, cy + 0.20 * s, cx - 0.40 * s, cy + 0.20 * s, (0.6, 0.6, 0.6), lw=3.0)
        o += _line(cx - 0.34 * s, cy + 0.05 * s, cx - 0.42 * s, cy + 0.05 * s, (0.6, 0.6, 0.6), lw=3.0)
    elif art == "reading":
        o += _circle(cx, cy + 0.22 * s, 0.09 * s, fill=(0.95, 0.75, 0.55))
        o += _poly([(cx - 0.22 * s, cy - 0.05 * s), (cx, cy + 0.02 * s), (cx, cy - 0.18 * s),
                    (cx - 0.22 * s, cy - 0.25 * s)], fill=(1, 1, 1), stroke=(0.15, 0.35, 0.70), lw=2.5)
        o += _poly([(cx + 0.22 * s, cy - 0.05 * s), (cx, cy + 0.02 * s), (cx, cy - 0.18 * s),
                    (cx + 0.22 * s, cy - 0.25 * s)], fill=(0.95, 0.95, 0.95), stroke=(0.15, 0.35, 0.70), lw=2.5)
    elif art in ("circle", "triangle", "square", "rectangle", "oval", "star"):
        o += _shape_outline(art, cx, cy, 0.30 * s, pal)
    elif art == "swatch":
        sw = _named_color(str(extra.get("swatch", "")))
        o += _circle(cx, cy, 0.26 * s, fill=sw, stroke=(0.2, 0.2, 0.2), lw=3.0)
        o += _circle(cx, cy, 0.32 * s, fill=None, stroke=pal, lw=3.0)
    else:  # emblem fallback: neutral geometric mark, no text
        o += _circle(cx, cy, 0.28 * s, fill=None, stroke=pal, lw=4.0)
        o += _poly([(cx, cy + 0.16 * s), (cx + 0.16 * s, cy),
                    (cx, cy - 0.16 * s), (cx - 0.16 * s, cy)], fill=pal)
        o += _circle(cx, cy, 0.05 * s, fill=(1, 1, 1))

    o += "Q "
    return o


def _shape_outline(shape: str, cx: float, cy: float, r: float, color) -> str:
    if shape == "circle":
        return _circle(cx, cy, r, fill=None, stroke=color, lw=6.0)
    if shape == "triangle":
        return _poly([(cx, cy + r), (cx + r, cy - r), (cx - r, cy - r)],
                     fill=None, stroke=color, lw=6.0)
    if shape == "square":
        return _poly([(cx - r, cy + r), (cx + r, cy + r), (cx + r, cy - r), (cx - r, cy - r)],
                     fill=None, stroke=color, lw=6.0)
    if shape == "rectangle":
        return _poly([(cx - r, cy + 0.65 * r), (cx + r, cy + 0.65 * r),
                      (cx + r, cy - 0.65 * r), (cx - r, cy - 0.65 * r)],
                     fill=None, stroke=color, lw=6.0)
    if shape == "oval":
        s = f"q {r:.1f} 0 0 {(0.62 * r):.1f} {cx:.1f} {cy:.1f} cm "
        s += _circle(0, 0, 1.0, fill=None, stroke=color, lw=6.0)
        return s + "Q "
    if shape == "star":
        pts = []
        for i in range(10):
            rr = r if i % 2 == 0 else 0.45 * r
            a = math.pi / 2 + i * math.pi / 5
            pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
        return _poly(pts, fill=None, stroke=color, lw=5.0)
    return ""


def _named_color(name: str) -> Tuple[float, float, float]:
    return {
        "red": (0.85, 0.12, 0.12), "blue": (0.15, 0.35, 0.85),
        "green": (0.12, 0.55, 0.20), "yellow": (0.95, 0.78, 0.08),
        "black": (0.10, 0.10, 0.10), "white": (0.96, 0.96, 0.96),
        "orange": (1.0, 0.55, 0.05), "pink": (0.95, 0.45, 0.60),
        "purple": (0.50, 0.20, 0.60), "brown": (0.50, 0.32, 0.18),
    }.get(name.strip().lower(), (0.20, 0.45, 0.80))
