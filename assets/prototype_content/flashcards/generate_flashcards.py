"""Phase 6: printable two-sided flashcard decks generated from the dataset.

Each A4 sheet holds 6 cards (2 x 3). Fronts are followed by a backs sheet with
columns mirrored, so duplex printing (flip on long edge) lines them up.

  front: the picture (colours: a full-card swatch)
  back:  the Santali word exactly as printed in the book (cropped label image),
         the English word, the category, and provenance / verification status

Writes flashcards/NN_<deck>.pdf, a master deck and flashcards/manifest.json.
"""
import json
import sys
from collections import OrderedDict

from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

from common import FLASHCARDS_DIR, ROOT, category_info, load_assets, load_taxonomy

BLUE = HexColor("#1E5AA8")
AMBER = HexColor("#F59E0B")
INK = HexColor("#1F2937")
MUTED = HexColor("#6B7280")
BORDER = HexColor("#CBD5E1")
PAGE_W, PAGE_H = A4
MARGIN = 12 * mm
GAP = 6 * mm
COLS, ROWS = 2, 3
CARD_W = (PAGE_W - 2 * MARGIN - GAP * (COLS - 1)) / COLS
CARD_H = (PAGE_H - 2 * MARGIN - GAP * (ROWS - 1)) / ROWS
DECK_NAME = "Santali Visual Vocabulary"


def card_origin(slot, mirrored=False):
    col, row = slot % COLS, slot // COLS
    if mirrored:
        col = COLS - 1 - col
    x = MARGIN + col * (CARD_W + GAP)
    y = PAGE_H - MARGIN - (row + 1) * CARD_H - row * GAP
    return x, y


def draw_image_fit(c, path, x, y, w, h):
    img = ImageReader(str(path))
    iw, ih = img.getSize()
    s = min(w / iw, h / ih)
    dw, dh = iw * s, ih * s
    c.drawImage(img, x + (w - dw) / 2, y + (h - dh) / 2, dw, dh, mask="auto")


def card_frame(c, x, y, fill=white):
    c.setFillColor(fill)
    c.setStrokeColor(BORDER)
    c.setLineWidth(0.8)
    c.roundRect(x, y, CARD_W, CARD_H, 5 * mm, stroke=1, fill=1)


def pill(c, text, x, y, color):
    c.setFont("Helvetica-Bold", 7.5)
    w = c.stringWidth(text, "Helvetica-Bold", 7.5) + 6 * mm
    c.setFillColor(color)
    c.roundRect(x, y, w, 5.5 * mm, 2.75 * mm, stroke=0, fill=1)
    c.setFillColor(white)
    c.drawString(x + 3 * mm, y + 1.8 * mm, text)
    return w


def draw_front(c, a, x, y, cat_label):
    if a["visual_type"] == "colour_swatch":
        card_frame(c, x, y)
        c.setFillColor(HexColor(a["hex"]))
        c.setStrokeColor(BORDER)
        inset = 8 * mm
        c.roundRect(x + inset, y + inset, CARD_W - 2 * inset, CARD_H - 2 * inset, 3 * mm, stroke=1, fill=1)
        return
    card_frame(c, x, y)
    pad = 7 * mm
    draw_image_fit(c, ROOT / a["asset"]["path"], x + pad, y + pad, CARD_W - 2 * pad, CARD_H - 2 * pad)


def draw_back(c, a, x, y, cat_label):
    card_frame(c, x, y)
    cx = x + CARD_W / 2
    # Santali as printed in the source (visual truth), in the upper half
    label = a["label"]["santali"]["label_image"]
    if label:
        box_w, box_h = CARD_W - 16 * mm, 22 * mm
        draw_image_fit(c, ROOT / label, x + 8 * mm, y + CARD_H * 0.52, box_w, box_h)
    # English
    english = a["label"]["english"].upper()
    size = 20
    while c.stringWidth(english, "Helvetica-Bold", size) > CARD_W - 12 * mm and size > 10:
        size -= 1
    c.setFillColor(INK)
    c.setFont("Helvetica-Bold", size)
    c.drawCentredString(cx, y + CARD_H * 0.36, english)
    # printed gloss if the book used a different English word
    printed = a["source_label"]["english"]
    if printed.lower().replace(" ", "_") != a["concept"] and a["concept"] != "human_body_diagram":
        c.setFont("Helvetica-Oblique", 7.5)
        c.setFillColor(MUTED)
        c.drawCentredString(cx, y + CARD_H * 0.36 - 5 * mm, f'book: "{printed}"')
    # category + status pills
    w = c.stringWidth(cat_label.upper(), "Helvetica-Bold", 7.5) + 6 * mm
    pill(c, cat_label.upper(), cx - w / 2, y + CARD_H * 0.17, BLUE)
    verified = a["label"]["santali"]["verified"]
    c.setFont("Helvetica", 6.5)
    c.setFillColor(MUTED)
    c.drawString(x + 5 * mm, y + 4 * mm, f"p.{a['source']['page']}  {a['id']}")
    status = "Santali verified" if verified else "Santali unverified"
    c.setFillColor(HexColor("#15803D") if verified else AMBER)
    c.drawRightString(x + CARD_W - 5 * mm, y + 4 * mm, status)


def cover(c, title, subtitle, count):
    c.setFillColor(BLUE)
    c.rect(0, PAGE_H - 70 * mm, PAGE_W, 70 * mm, stroke=0, fill=1)
    c.setFillColor(white)
    c.setFont("Helvetica-Bold", 26)
    c.drawString(MARGIN + 4 * mm, PAGE_H - 35 * mm, title)
    c.setFont("Helvetica", 12)
    c.drawString(MARGIN + 4 * mm, PAGE_H - 45 * mm, subtitle)
    c.setFillColor(AMBER)
    c.rect(0, PAGE_H - 72 * mm, PAGE_W, 2 * mm, stroke=0, fill=1)
    c.setFillColor(INK)
    c.setFont("Helvetica", 11)
    lines = [f"{count} cards  -  printed 6 per A4 sheet.",
             "Print double-sided, flip on LONG edge: each backs sheet lines up with the fronts before it.",
             "Front: picture.  Back: Santali word as printed in the source book, English word, category.",
             "Source: Aao Santali Likhna Sikhe (Dr. Ram Dayal Munda Tribal Welfare Research Institute, Jharkhand).",
             "Santali words marked 'unverified' have not yet been checked by a Santali reader."]
    for i, line in enumerate(lines):
        c.drawString(MARGIN + 4 * mm, PAGE_H - 90 * mm - i * 7 * mm, line)
    c.showPage()


def render_deck(path, title, cards):
    """cards: list of (asset, category_label)"""
    c = canvas.Canvas(str(path), pagesize=A4)
    c.setTitle(title)
    c.setAuthor(DECK_NAME)
    cover(c, title, DECK_NAME, len(cards))
    per_sheet = COLS * ROWS
    for start in range(0, len(cards), per_sheet):
        chunk = cards[start:start + per_sheet]
        for slot, (a, lab) in enumerate(chunk):
            draw_front(c, a, *card_origin(slot), lab)
        c.showPage()
        for slot, (a, lab) in enumerate(chunk):
            draw_back(c, a, *card_origin(slot, mirrored=True), lab)
        c.showPage()
    c.save()


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    taxonomy = load_taxonomy()
    data = load_assets()
    FLASHCARDS_DIR.mkdir(exist_ok=True)

    decks = OrderedDict()
    for a in data["assets"]:
        if a["concept"] == "human_body_diagram":   # reference diagram, no single word to learn
            continue
        node = category_info(taxonomy, a["category"], a["subcategory"])
        decks.setdefault(node["deck"], {"label": node["label"], "cards": []})["cards"].append((a, node["label"]))

    manifest = {"deck": {"name": DECK_NAME, "source": data["source"]["document"]}, "decks": [], "cards": []}
    master = []
    for deck_id in sorted(decks):
        d = decks[deck_id]
        path = FLASHCARDS_DIR / f"{deck_id}.pdf"
        render_deck(path, d["label"], d["cards"])
        master += d["cards"]
        manifest["decks"].append({"deck_id": deck_id, "title": d["label"], "file": path.relative_to(ROOT).as_posix(),
                                  "card_count": len(d["cards"])})
        for a, lab in d["cards"]:
            manifest["cards"].append({
                "card_id": a["id"], "asset_id": a["id"], "deck_id": deck_id,
                "front": {"image": a["asset"]["path"], **({"hex": a["hex"]} if "hex" in a else {})},
                "back": {"santali": a["label"]["santali"]["value"],
                         "santali_image": a["label"]["santali"]["label_image"],
                         "santali_verified": a["label"]["santali"]["verified"],
                         "english": a["label"]["english"].upper(), "category": lab.upper()},
            })
        print(f"{deck_id}: {len(d['cards'])} cards -> {path.relative_to(ROOT)}")

    master_path = FLASHCARDS_DIR / "Santali_Visual_Vocabulary_Master.pdf"
    render_deck(master_path, "All categories", master)
    manifest["master"] = {"file": master_path.relative_to(ROOT).as_posix(), "card_count": len(master)}
    (FLASHCARDS_DIR / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"master: {len(master)} cards -> {master_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
