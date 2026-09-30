"""Real flashcard PDF renderer (dependency-free, one card per page).

Visual-first composition: topic header, large visual area (~55% of the
card) — the bundled catalog PNG for IMAGE_CATALOG cards, a vector
illustration for AI_GENERATED cards — then language hierarchy (primary word large, secondary smaller,
Santali equivalent), optional pronunciation line, footer
"Listen - Repeat - Learn" + page counter. Typography rendered by the
composer — visuals never contain words.

Santali script note: text is encoded as UTF-16BE hex (same approach as
the worksheet pipeline) so the real translated content is preserved in
the PDF; readers with Ol Chiki coverage render it, and the pipeline only
needs a font-embedding change to ship embedded glyphs later.
"""
from __future__ import annotations

import struct
from typing import List, Optional, Tuple

from app.flashcards.schemas import FlashcardDocument
from app.flashcards.vector_art import draw_art, parse_hex

_PAGE_W, _PAGE_H = 595.0, 842.0  # A4 points
_MARGIN = 48.0


def _escape_text(text: str) -> str:
    if not text:
        return "<FEFF>"
    raw = text.encode("utf-16-be", errors="replace")
    return "<FEFF" + raw.hex().upper() + ">"


def _wrap(text: str, max_chars: int) -> List[str]:
    words = (text or "").split()
    lines: List[str] = []
    cur = ""
    for w in words:
        probe = (cur + " " + w).strip()
        if len(probe) <= max_chars:
            cur = probe
        else:
            if cur:
                lines.append(cur)
            while len(w) > max_chars:
                lines.append(w[:max_chars])
                w = w[max_chars:]
            cur = w
    if cur:
        lines.append(cur)
    return lines or [""]


def _text_line(x: float, y: float, size: int, text: str, center: float | None = None) -> str:
    if center is not None:
        # Rough centering offset for the card aesthetic.
        x = max(_MARGIN, center - len(text) * size * 0.30)
    return f"BT /F1 {size} Tf {x:.1f} {y:.1f} Td {_escape_text(text)} Tj ET\n"


def _catalog_png(visual: dict) -> Optional[Tuple[int, int, bytes]]:
    """(width, height, zlib IDAT data) of a catalog card's PNG, or None.

    Catalog PNGs are 8-bit RGB, non-interlaced: their IDAT stream embeds
    directly as a FlateDecode image with the PNG predictor (no decoding,
    no image library). The path is resolved inside the catalog only.
    """
    if visual.get("kind") != "image":
        return None
    from app.flashcards.image_library import FLUTTER_ASSET_ROOT, flashcard_image_library

    rel = str(visual.get("image") or "")
    prefix = FLUTTER_ASSET_ROOT + "/"
    if rel.startswith(prefix):
        rel = rel[len(prefix):]
    path = flashcard_image_library.resolve_asset(rel)
    if path is None:
        return None
    try:
        data = path.read_bytes()
    except OSError:
        return None
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    pos, idat = 8, bytearray()
    width = height = 0
    while pos + 8 <= len(data):
        length, ctype = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + length]
        if ctype == b"IHDR":
            width, height, depth, colour, _, _, interlace = struct.unpack(">IIBBBBB", body)
            if depth != 8 or colour != 2 or interlace != 0:
                return None
        elif ctype == b"IDAT":
            idat += body
        elif ctype == b"IEND":
            break
        pos += 12 + length
    if not width or not idat:
        return None
    return width, height, bytes(idat)


def render_flashcard_pdf(doc: FlashcardDocument) -> bytes:
    meta = doc.metadata or {}
    mode = meta.get("language_mode", "hi_sat")
    cx = _PAGE_W / 2.0
    pages: List[str] = []
    page_images: List[Optional[Tuple[int, int, bytes]]] = []

    for card in doc.cards:
        s = ""
        y = _PAGE_H - _MARGIN
        # Card border (rounded aesthetic approximated with a rect stroke).
        s += f"0.1 0.47 0.3 RG 2 w {_MARGIN:.1f} {_MARGIN:.1f} {_PAGE_W - 2 * _MARGIN:.1f} {_PAGE_H - 2 * _MARGIN:.1f} re S\n"
        s += _text_line(_MARGIN, y, 13, str(meta.get("topic", doc.title)).upper(), cx)
        y -= 24
        s += _text_line(_MARGIN, y, 10, f"Class {meta.get('grade', '')}  {meta.get('subject', '')}  {card.type}", cx)
        y -= 30
        # Visual area ~55% of card: the bundled catalog PNG for
        # IMAGE_CATALOG cards, otherwise a vector illustration painted with
        # PDF operators (never emoji, never words inside the image).
        visual = card.visual or {}
        art_cy = y - 95.0
        png = _catalog_png(visual)
        page_images.append(png)
        if png is not None:
            w, h, _ = png
            scale = 190.0 / max(w, h)
            dw, dh = w * scale, h * scale
            s += f"q {dw:.1f} 0 0 {dh:.1f} {cx - dw / 2:.1f} {art_cy - dh / 2:.1f} cm /Im1 Do Q\n"
        else:
            art = str(visual.get("art") or "emblem")
            palette = parse_hex(str(visual.get("palette") or "#1B7A4D"))
            extra = {"count": visual.get("count"), "swatch": visual.get("swatch")}
            s += draw_art(art, cx, art_cy, 150.0, palette, extra)
        y -= 200.0
        y -= 14
        # Language hierarchy: primary large, secondary medium, Santali distinct.
        primary, secondary = None, None
        if mode == "hi_sat":
            primary, secondary = (card.hindi or ""), None
        elif mode == "en_sat":
            primary, secondary = (card.english or ""), None
        else:
            primary, secondary = (card.hindi or ""), (card.english or "")
        for ln in _wrap(primary, 30):
            s += _text_line(_MARGIN, y, 26, ln, cx)
            y -= 30
        if secondary:
            for ln in _wrap(secondary, 36):
                s += _text_line(_MARGIN, y, 18, ln, cx)
                y -= 22
        for ln in _wrap(card.santali, 30):
            s += _text_line(_MARGIN, y, 22, ln, cx)
            y -= 26
        if meta.get("pronunciation"):
            s += _text_line(_MARGIN, y, 9, "[ pronunciation audio available in app ]", cx)
            y -= 16
        # Object-identification prompt composition.
        if card.type == "object_identification":
            s += _text_line(_MARGIN, y, 12, "What is this?", cx)
            y -= 18
        elif card.type == "number":
            s += _text_line(_MARGIN, y, 11, f"Card {card.number}", cx)
            y -= 16
        s += _text_line(_MARGIN, _MARGIN + 26, 10, "Listen - Repeat - Learn", cx)
        s += _text_line(_MARGIN, _MARGIN + 10, 10,
                        f"{card.number:02d} / {len(doc.cards):02d}", cx)
        pages.append(s)

    objects: List[bytes] = []
    n_pages = len(pages)
    font_obj = 3 + 2 * n_pages
    # Image XObjects follow the font object, one per catalog page.
    image_obj = {}
    for i, png in enumerate(page_images):
        if png is not None:
            image_obj[i] = font_obj + 1 + len(image_obj)
    kids = " ".join(f"{3 + 2 * i} 0 R" for i in range(n_pages))
    objects.append(b"<< /Type /Catalog /Pages 2 0 R >>")
    objects.append(f"<< /Type /Pages /Kids [{kids}] /Count {n_pages} >>".encode("latin-1"))
    for i, stream_text in enumerate(pages):
        content_obj = 4 + 2 * i
        xobject = f" /XObject << /Im1 {image_obj[i]} 0 R >>" if i in image_obj else ""
        objects.append(
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {_PAGE_W:.0f} {_PAGE_H:.0f}] "
            f"/Resources << /Font << /F1 {font_obj} 0 R >>{xobject} >> /Contents {content_obj} 0 R >>".encode("latin-1")
        )
        stream = stream_text.encode("latin-1")
        objects.append(
            f"<< /Length {len(stream)} >>\nstream\n".encode("latin-1") + stream + b"\nendstream"
        )
    objects.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
    for i in sorted(image_obj):
        w, h, idat = page_images[i]
        objects.append(
            (f"<< /Type /XObject /Subtype /Image /Width {w} /Height {h} "
             f"/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode "
             f"/DecodeParms << /Predictor 15 /Colors 3 /BitsPerComponent 8 /Columns {w} >> "
             f"/Length {len(idat)} >>\nstream\n").encode("latin-1") + idat + b"\nendstream"
        )

    out = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for idx, body in enumerate(objects, start=1):
        offsets.append(len(out))
        out += f"{idx} 0 obj\n".encode("latin-1") + body + b"\nendobj\n"
    xref_pos = len(out)
    out += f"xref\n0 {len(objects) + 1}\n".encode("latin-1")
    out += b"0000000000 65535 f \n"
    for off in offsets[1:]:
        out += f"{off:010d} 00000 n \n".encode("latin-1")
    out += (
        f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\n"
        f"startxref\n{xref_pos}\n%%EOF"
    ).encode("latin-1")
    return bytes(out)
