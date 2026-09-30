"""Real worksheet PDF renderer (dependency-free).

Renders the ACTUAL generated WorksheetDocument into a valid PDF file —
never mock/placeholder content. Implemented against the PDF 1.4 spec with
standard Type1 Helvetica so no third-party library or font file is needed.

Unicode note: text is encoded as UTF-16BE hex strings. Base-14 Helvetica
has no Devanagari/Ol Chiki glyphs, so rendering of non-Latin scripts falls
back to the PDF reader's font substitution (Chrome/Adobe/mobile readers do
this automatically). The CONTENT itself is always the real worksheet: every
question, both language sides, options, answers and metadata. If the
deployment later embeds a full Unicode TTF, only _font_resources() needs to
change — the content pipeline stays identical.
"""
from __future__ import annotations

from typing import List

from app.worksheets.schemas import WorksheetDocument

_PAGE_W, _PAGE_H = 595.0, 842.0  # A4 points
_MARGIN = 48.0
_LINE_H = 14.0
_TITLE_H = 18.0


def _escape_text(text: str) -> str:
    """Encode text as a PDF UTF-16BE hex string <FEFF...>."""
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
            # hard-split very long tokens (URLs, long words)
            while len(w) > max_chars:
                lines.append(w[:max_chars])
                w = w[max_chars:]
            cur = w
    if cur:
        lines.append(cur)
    return lines or [""]


def _text_line(x: float, y: float, size: int, text: str) -> str:
    return f"BT /F1 {size} Tf {x:.1f} {y:.1f} Td {_escape_text(text)} Tj ET\n"


def render_worksheet_pdf(doc: WorksheetDocument) -> bytes:
    """Render the real worksheet content to PDF bytes."""
    meta = doc.metadata or {}
    grade = meta.get("grade", "")
    section = meta.get("section") or "General"
    subject = meta.get("subject", "")
    topic = meta.get("topic", "")
    src = meta.get("source_language", "")
    tgt = meta.get("target_language", "")
    types = meta.get("worksheet_types") or [meta.get("worksheet_type", "practice")]
    difficulty = meta.get("difficulty", "")
    nipun = meta.get("nipun_code") or meta.get("nipun_outcome") or "custom topic"

    pages_content: List[str] = []
    cur_lines: List[str] = []
    y = _PAGE_H - _MARGIN

    def push(line: str, size: int = 10, gap: float = _LINE_H) -> None:
        nonlocal y
        if y < _MARGIN + gap:
            pages_content.append("".join(cur_lines))
            cur_lines.clear()
            y = _PAGE_H - _MARGIN
        cur_lines.append(_text_line(_MARGIN, y, size, line))
        y -= gap

    def push_wrapped(text: str, size: int = 10) -> None:
        for ln in _wrap(text, 88):
            push(ln, size)

    # Header (real metadata, never demo values).
    push("NIPUN BHARAT BILINGUAL WORKSHEET", 14, _TITLE_H)
    push_wrapped(str(doc.title.source or ""))
    if doc.title.target and doc.title.target != doc.title.source:
        push_wrapped(str(doc.title.target))
    push(f"Class {grade}  Section {section}  {subject}", 10)
    push(f"Topic: {topic}   NIPUN: {nipun}", 10)
    push(f"Languages: {src} + {tgt}   Types: {', '.join(types)}", 10)
    push(f"Difficulty: {difficulty}   Questions: {len(doc.questions)}", 10)
    push("Name: ____________________   Date: ____/____/________", 10)
    push("", 10)
    push_wrapped(f"Instructions: {doc.instructions.source or ''}")
    if doc.instructions.target and doc.instructions.target != doc.instructions.source:
        push_wrapped(str(doc.instructions.target))
    push("", 10)

    for q in doc.questions:
        push(f"Q{q.number} [{q.type}]", 11)
        push_wrapped(str(q.prompt.source or ""))
        if q.prompt.target and q.prompt.target != q.prompt.source:
            push_wrapped(str(q.prompt.target))
        for opt in q.options or []:
            text = opt.get("text", {}) if isinstance(opt, dict) else {}
            label = ""
            if isinstance(text, dict):
                label = str(text.get("target") or text.get("source") or opt.get("value", ""))
            else:
                label = str((opt.get("value", "") if isinstance(opt, dict) else opt))
            oid = opt.get("option_id", "") if isinstance(opt, dict) else ""
            push_wrapped(f"  ({oid}) {label}")
        if q.visual:
            push_wrapped(f"  [visual: {q.visual}]")
        if meta.get("bilingual_answers"):
            push("  Answer: _______________", 10)
        push("", 6)

    if doc.teacher_notes and (doc.teacher_notes.source or doc.teacher_notes.target):
        push("Teacher notes:", 11)
        if doc.teacher_notes.source:
            push_wrapped(str(doc.teacher_notes.source))
        if doc.teacher_notes.target and doc.teacher_notes.target != doc.teacher_notes.source:
            push_wrapped(str(doc.teacher_notes.target))

    pages_content.append("".join(cur_lines))

    # Assemble PDF objects.
    objects: List[bytes] = []
    # 1: Catalog, 2: Pages, then per-page Page + Contents, then Font.
    n_pages = len(pages_content)
    # object numbering: 1 catalog, 2 pages, (3,4) (5,6)... page+content, last font
    font_obj = 3 + 2 * n_pages
    kids = " ".join(f"{3 + 2 * i} 0 R" for i in range(n_pages))
    objects.append(b"<< /Type /Catalog /Pages 2 0 R >>")  # 1
    objects.append(f"<< /Type /Pages /Kids [{kids}] /Count {n_pages} >>".encode("latin-1"))  # 2
    for i, stream_text in enumerate(pages_content):
        page_obj = 3 + 2 * i
        content_obj = 4 + 2 * i
        objects.append(
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {_PAGE_W:.0f} {_PAGE_H:.0f}] "
            f"/Resources << /Font << /F1 {font_obj} 0 R >> >> /Contents {content_obj} 0 R >>".encode("latin-1")
        )
        stream = stream_text.encode("latin-1")
        objects.append(
            f"<< /Length {len(stream)} >>\nstream\n".encode("latin-1") + stream + b"\nendstream"
        )
    objects.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")

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
