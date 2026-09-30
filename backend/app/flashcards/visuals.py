"""Visual asset resolution strategy for flashcards.

Priority per concept:
1. Existing curated educational visual asset (registry below).
2. Existing bundled/local visual (same registry, source=bundled).
3. Generated educational illustration descriptor (source=generated).
4. Simple vector illustration fallback (source=vector).

Every resolved visual carries an ``art`` key naming a real vector
illustration routine (see ``vector_art.draw_art``) plus ``count`` /
``swatch`` parameters where the card type needs them (counting cards draw
N items; color cards draw the named color). Renderers paint ``art`` —
never emoji, never stock/decorative images, never words inside the image.
The ``glyph`` field is legacy metadata for older clients only.
"""
from __future__ import annotations

from typing import Any, Dict, Optional

# Curated educational visuals: english concept -> (art routine, asset ref).
_CURATED: Dict[str, tuple] = {
    "mango": ("mango", "curated/fruits/mango.png"),
    "banana": ("banana", "curated/fruits/banana.png"),
    "guava": ("guava", "curated/fruits/guava.png"),
    "papaya": ("papaya", "curated/fruits/papaya.png"),
    "orange": ("orange", "curated/fruits/orange.png"),
    "apple": ("apple", "curated/fruits/apple.png"),
    "grapes": ("grapes", "curated/fruits/grapes.png"),
    "pomegranate": ("apple", "curated/fruits/pomegranate.png"),
    "watermelon": ("orange", "curated/fruits/watermelon.png"),
    "lemon": ("orange", "curated/fruits/lemon.png"),
    "cow": ("cow", "curated/animals/cow.png"),
    "goat": ("goat", "curated/animals/goat.png"),
    "dog": ("dog", "curated/animals/dog.png"),
    "cat": ("dog", "curated/animals/cat.png"),
    "elephant": ("cow", "curated/animals/elephant.png"),
    "horse": ("cow", "curated/animals/horse.png"),
    "hen": ("hen", "curated/animals/hen.png"),
    "rabbit": ("dog", "curated/animals/rabbit.png"),
    "parrot": ("bird", "curated/animals/parrot.png"),
    "book": ("book", "curated/objects/book.png"),
    "pen": ("book", "curated/objects/pen.png"),
    "ball": ("ball", "curated/objects/ball.png"),
    "chair": ("book", "curated/objects/chair.png"),
    "umbrella": ("tree", "curated/objects/umbrella.png"),
    "sun": ("sun", "curated/nature/sun.png"),
    "moon": ("moon", "curated/nature/moon.png"),
    "tree": ("tree", "curated/nature/tree.png"),
    "flower": ("flower", "curated/nature/flower.png"),
    "fish": ("fish", "curated/animals/fish.png"),
    "bird": ("bird", "curated/animals/bird.png"),
    "red": ("swatch", "curated/colors/red.png"),
    "blue": ("swatch", "curated/colors/blue.png"),
    "green": ("swatch", "curated/colors/green.png"),
    "yellow": ("swatch", "curated/colors/yellow.png"),
    "black": ("swatch", "curated/colors/black.png"),
    "white": ("swatch", "curated/colors/white.png"),
    "circle": ("circle", "curated/shapes/circle.png"),
    "triangle": ("triangle", "curated/shapes/triangle.png"),
    "square": ("square", "curated/shapes/square.png"),
    "rectangle": ("rectangle", "curated/shapes/rectangle.png"),
    "oval": ("oval", "curated/shapes/oval.png"),
    "star": ("star", "curated/shapes/star.png"),
    "running": ("running", "curated/actions/running.png"),
    "eating": ("running", "curated/actions/eating.png"),
    "drinking": ("running", "curated/actions/drinking.png"),
    "reading": ("reading", "curated/actions/reading.png"),
    "writing": ("reading", "curated/actions/writing.png"),
    "playing": ("ball", "curated/actions/playing.png"),
    "sleeping": ("moon", "curated/actions/sleeping.png"),
    "eye": ("eye", "curated/body/eye.png"),
    "nose": ("triangle", "curated/body/nose.png"),
    "ear": ("oval", "curated/body/ear.png"),
    "hand": ("hand", "curated/body/hand.png"),
    "foot": ("oval", "curated/body/foot.png"),
    "head": ("circle", "curated/body/head.png"),
}

_PALETTES = ["#1B7A4D", "#1565C0", "#E65100", "#6A1B9A", "#00695C", "#AD1457"]


def _lookup_art(concept_en: str) -> Optional[tuple]:
    key = (concept_en or "").lower()
    candidates = [key]
    for token in key.replace("(", " ").replace(")", " ").split():
        if token not in candidates:
            candidates.append(token)
    for cand in candidates:
        if cand in _CURATED:
            return _CURATED[cand]
    return None


def resolve_visual(
    concept_en: str,
    concept_hi: str,
    style: str,
    index: int,
    flashcard_type: str = "vocabulary",
    count: Optional[int] = None,
) -> Dict[str, Any]:
    """Resolve a meaningful visual descriptor for one concept."""
    found = _lookup_art(concept_en or "")
    if found is not None:
        art, asset = found
        source = "curated"
    else:
        art, asset = "emblem", f"generated/{(concept_en or 'concept').lower().replace(' ', '_')}.png"
        source = "vector" if style == "vector" else "generated"

    # Card-type composition rules.
    extra_count = count
    swatch = None
    if flashcard_type == "number":
        art, source = "apples", "vector"
        extra_count = count if count else ((index % 10) + 1)
        asset = "vector/counting/apples.png"
    elif flashcard_type == "color":
        art, source = "swatch", "vector"
        swatch = (concept_en or "").strip().lower()
        asset = f"vector/colors/{swatch or 'color'}.png"
    elif flashcard_type == "shape":
        shape = (concept_en or "").strip().lower()
        if shape in ("circle", "triangle", "square", "rectangle", "oval", "star"):
            art, source = shape, "vector"
            asset = f"vector/shapes/{shape}.png"

    return {
        "source": source,
        "art": art,
        "count": extra_count,
        "swatch": swatch,
        "asset_ref": asset,
        "description_en": f"Educational illustration of {concept_en or concept_hi}",
        "palette": _PALETTES[index % len(_PALETTES)],
        "style": style,
        "has_text": False,
    }
