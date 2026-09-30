"""Prototype flashcard image catalog (image-first flashcard generation).

The Flutter app bundles a curated Santali visual vocabulary dataset at
``assets/prototype_content/flashcards`` — the single source of truth:

* ``metadata/assets.json``: one record per picture (``id``, ``category``,
  ``subcategory``, ``concept``, ``label.english``, ``label.santali``
  (Ol Chiki value + cropped label image), ``source_label.hindi``,
  ``asset.path``, ``caption``, ``visual_type``, source-book provenance,
  ``review``).
* ``config/taxonomy.json``: categories/subcategories + keywords.

The catalog carries no grade, subject or learning-outcome fields.

When a requested topic maps to a catalog category, flashcards are built
deterministically from its pictures and printed labels (source
``IMAGE_CATALOG``) — no Sarvam or other LLM call. Only topics the catalog
does not cover fall back to the Sarvam pipeline (``AI_GENERATED``). The
catalog lookup always happens BEFORE any provider is invoked.
"""
from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

# Flutter asset prefix (pictures are bundled into the app; the backend
# stores this logical, repository-relative path — never a disk path).
FLUTTER_ASSET_ROOT = "assets/prototype_content/flashcards"

SOURCE_IMAGE_CATALOG = "IMAGE_CATALOG"
SOURCE_AI_GENERATED = "AI_GENERATED"
PROVIDER_NAME = "prototype-catalog"
# ``topic_source`` sent by clients when the teacher picked a catalog topic.
TOPIC_SOURCE_CATALOG = "image_catalog"

# Hindi topic hints per catalog key (the taxonomy is English-only).
_HINDI_HINTS: Dict[str, List[str]] = {
    "animals": ["जानवर", "पशु"],
    "domestic_animals": ["पालतू"],
    "wild_animals": ["जंगली"],
    "birds": ["पक्षी", "चिड़िया"],
    "vegetables": ["सब्जी", "सब्ज़ी", "सब्जियां", "सब्जियाँ"],
    "fruits": ["फल"],
    "flowers": ["फूल"],
    "water_animals": ["जलीय", "पानी के जीव", "पानी के जानवर"],
    "insects": ["कीड़े", "कीड़ा", "कीट"],
    "residence": ["घर", "आवास", "निवास"],
    "transport": ["वाहन", "परिवहन", "यातायात", "सवारी"],
    "relations": ["परिवार", "रिश्ते", "रिश्तेदार", "संबंध"],
    "body_parts": ["शरीर", "अंग"],
    "colours": ["रंग"],
}

# Extra English synonyms not present in the taxonomy keywords.
_ENGLISH_HINTS: Dict[str, List[str]] = {
    "colours": ["colors", "colours"],
    "body_parts": ["body", "body parts", "parts of body"],
    "residence": ["house", "houses", "homes"],
    "relations": ["family", "relatives", "relationships"],
    "transport": ["vehicles", "means of transport"],
    "water_animals": ["sea animals", "aquatic animals"],
    "insects": ["insects", "bugs"],
}


@dataclass
class LibraryDeck:
    """One selectable catalog topic (a taxonomy category or subcategory)."""

    id: str
    key: str
    label: str
    category: str
    subcategory: Optional[str]
    keywords: List[str] = field(default_factory=list)
    assets: List[Dict[str, Any]] = field(default_factory=list)

    @property
    def card_count(self) -> int:
        return len(self.assets)

    def to_summary(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "key": self.key,
            "label": self.label,
            "category": self.category,
            "subcategory": self.subcategory,
            "card_count": self.card_count,
            "keywords": self.keywords,
        }


def _default_library_dir() -> Path:
    # backend/app/flashcards/image_library.py -> repository root.
    return Path(__file__).resolve().parents[3] / FLUTTER_ASSET_ROOT


def _normalize(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").replace("_", " ").strip().lower())


def _keyword_in(keyword: str, haystack: str) -> bool:
    if not keyword:
        return False
    if keyword.isascii():
        return re.search(rf"(?<![a-z]){re.escape(keyword)}(?![a-z])", haystack) is not None
    return keyword in haystack


class FlashcardImageLibrary:
    """Loads the prototype catalog and resolves topics to catalog decks."""

    def __init__(self, root: Optional[Path] = None):
        self._root_override = root
        self._decks: Optional[List[LibraryDeck]] = None
        self._assets: List[Dict[str, Any]] = []

    @property
    def root(self) -> Path:
        if self._root_override is not None:
            return self._root_override
        from app.core.config import settings

        configured = getattr(settings, "FLASHCARD_IMAGE_LIBRARY_DIR", None)
        return Path(configured) if configured else _default_library_dir()

    def resolve_asset(self, relative: str) -> Optional[Path]:
        """Existing file for a catalog-relative path, confined to the catalog.

        Absolute paths and traversal (``../``) are rejected.
        """
        rel = (relative or "").replace("\\", "/").strip()
        if not rel or rel.startswith("/") or re.match(r"^[a-zA-Z]:", rel):
            return None
        root = self.root.resolve()
        try:
            candidate = (root / rel).resolve()
            candidate.relative_to(root)
        except (ValueError, OSError):
            return None
        return candidate if candidate.is_file() else None

    def _load(self) -> List[LibraryDeck]:
        if self._decks is not None:
            return self._decks
        root = self.root
        try:
            assets_doc = json.loads((root / "metadata" / "assets.json").read_text(encoding="utf-8"))
            taxonomy = json.loads((root / "config" / "taxonomy.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            logger.warning("Flashcard image catalog unavailable at %s: %s", root, exc)
            self._decks = []
            return self._decks

        assets = [a for a in assets_doc.get("assets", []) if isinstance(a, dict)]
        self._assets = assets
        tax_keywords: Dict[str, List[str]] = taxonomy.get("keywords", {}) or {}
        decks: List[LibraryDeck] = []
        for cat_key, cat in (taxonomy.get("categories") or {}).items():
            subs = cat.get("subcategories")
            if isinstance(subs, dict) and subs:
                sub_decks = []
                for sub_key, sub in subs.items():
                    sub_decks.append(LibraryDeck(
                        id=str(sub.get("deck") or f"{cat_key}_{sub_key}"),
                        key=sub_key,
                        label=str(sub.get("label") or sub_key),
                        category=cat_key,
                        subcategory=sub_key,
                        assets=[a for a in assets
                                if a.get("category") == cat_key and a.get("subcategory") == sub_key],
                    ))
                decks.extend(sub_decks)
                # Parent topic ("Animals") spans all its subcategories.
                decks.append(LibraryDeck(
                    id=cat_key,
                    key=cat_key,
                    label=str(cat.get("label") or cat_key),
                    category=cat_key,
                    subcategory=None,
                    assets=[a for d in sub_decks for a in d.assets],
                ))
            else:
                decks.append(LibraryDeck(
                    id=str(cat.get("deck") or cat_key),
                    key=cat_key,
                    label=str(cat.get("label") or cat_key),
                    category=cat_key,
                    subcategory=None,
                    assets=[a for a in assets if a.get("category") == cat_key],
                ))

        for deck in decks:
            words = {_normalize(deck.label), _normalize(deck.key)}
            words.update(_normalize(k) for k in tax_keywords.get(deck.key, []))
            words.update(_normalize(k) for k in _ENGLISH_HINTS.get(deck.key, []))
            words.update(_HINDI_HINTS.get(deck.key, []))
            # Singular forms: "fruits" -> "fruit", "birds" -> "bird".
            words.update(w[:-1] for w in list(words) if w.isascii() and w.endswith("s") and len(w) > 3)
            deck.keywords = sorted(w for w in words if w)

        # A keyword shared by several decks is ambiguous ("food", "plant"):
        # it cannot pick a topic on its own.
        owners: Dict[str, int] = {}
        for deck in decks:
            for w in deck.keywords:
                owners[w] = owners.get(w, 0) + 1
        for deck in decks:
            deck.keywords = [w for w in deck.keywords if owners[w] == 1]

        self._decks = [d for d in decks if d.assets]
        return self._decks

    def decks(self) -> List[LibraryDeck]:
        return list(self._load())

    def deck_by_id(self, topic_id: Optional[str]) -> Optional[LibraryDeck]:
        if not topic_id:
            return None
        for d in self._load():
            if topic_id in (d.id, d.key):
                return d
        return None

    def find_deck(self, topic: str, topic_id: Optional[str] = None) -> Optional[LibraryDeck]:
        """Resolve a teacher topic (or a catalog deck id) to a catalog deck."""
        by_id = self.deck_by_id(topic_id)
        if by_id is not None:
            return by_id
        hay = _normalize(topic)
        if not hay:
            return None
        best: Optional[LibraryDeck] = None
        best_score = 0
        for d in self._load():
            for w in d.keywords:
                if len(w) > best_score and _keyword_in(w, hay):
                    best, best_score = d, len(w)
        return best

    def asset_path(self, relative: str) -> str:
        return f"{FLUTTER_ASSET_ROOT}/{relative.replace(chr(92), '/').lstrip('/')}"

    @staticmethod
    def _labels(a: Dict[str, Any]) -> Dict[str, Any]:
        label = a.get("label") or {}
        santali = label.get("santali") or {}
        english = (label.get("english") or a.get("concept") or "").strip().replace("_", " ")
        return {
            "english": english[:1].upper() + english[1:],
            "hindi": ((a.get("source_label") or {}).get("hindi") or "").strip(),
            "santali": (santali.get("value") or "").strip(),
            "label_image": (santali.get("label_image") or "").strip(),
            "image": ((a.get("asset") or {}).get("path") or "").strip(),
        }

    def build_cards(self, deck: LibraryDeck, include_hindi: bool, limit: int) -> List[Dict[str, Any]]:
        """Card data for up to ``limit`` pictures of ``deck``.

        A picture is used only when its file exists and it carries the
        printed Santali word (and the Hindi label when the language mode
        shows Hindi). Nothing is translated or invented here.
        """
        cards: List[Dict[str, Any]] = []
        seen = set()
        for a in deck.assets:
            lb = self._labels(a)
            if not lb["santali"] or not lb["english"] or self.resolve_asset(lb["image"]) is None:
                continue
            if include_hindi and not lb["hindi"]:
                continue
            key = (lb["english"].lower(), lb["santali"])
            if key in seen:
                continue
            seen.add(key)
            src = a.get("source") or {}
            label_image = lb["label_image"]
            if label_image and self.resolve_asset(label_image) is None:
                label_image = ""
            cards.append({
                "asset_id": a.get("id"),
                "concept": lb["english"],
                "hindi": lb["hindi"] or None,
                "english": lb["english"],
                "santali": lb["santali"],
                "image": self.asset_path(lb["image"]),
                "label_image": self.asset_path(label_image) if label_image else None,
                "visual_type": a.get("visual_type"),
                "caption": a.get("caption"),
                "hex": a.get("hex"),
                "source_document": src.get("document"),
                "source_page": src.get("printed_page_number") or src.get("page"),
                "verified": bool((a.get("review") or {}).get("verified")),
            })
            if len(cards) >= limit:
                break
        return cards

    def catalog_items(self) -> List[Dict[str, Any]]:
        """One entry per catalog picture (metadata that actually exists)."""
        self._load()
        items = []
        for a in self._assets:
            lb = self._labels(a)
            langs = [code for code, text in (("en", lb["english"]), ("hi", lb["hindi"]),
                                             ("sat", lb["santali"])) if text]
            items.append({
                "asset_id": a.get("id"),
                "category": a.get("category"),
                "subcategory": a.get("subcategory"),
                "concept": a.get("concept"),
                "english": lb["english"] or None,
                "hindi": lb["hindi"] or None,
                "santali": lb["santali"] or None,
                "script": "Ol Chiki" if lb["santali"] else None,
                "visual_type": a.get("visual_type"),
                "asset_path": self.asset_path(lb["image"]) if lb["image"] else None,
                "image_available": self.resolve_asset(lb["image"]) is not None,
                "available_languages": langs,
                "verified": bool((a.get("review") or {}).get("verified")),
            })
        return items

    def coverage_report(self) -> Dict[str, Any]:
        """Catalog integrity summary; malformed entries are reported, not hidden."""
        decks = self._load()
        items = self.catalog_items()
        ids = [i["asset_id"] for i in items]
        in_decks = {a.get("id") for d in decks for a in d.assets}
        return {
            "total_images": len(items),
            "total_topics": len(decks),
            "complete_trilingual_items": sum(
                1 for i in items if i["image_available"] and i["hindi"] and i["english"] and i["santali"]),
            "language_combinations": sorted({"+".join(i["available_languages"]) for i in items}),
            "duplicate_asset_ids": sorted({x for x in ids if x and ids.count(x) > 1}),
            "missing_asset_id": sum(1 for x in ids if not x),
            "broken_images": [i["asset_id"] for i in items if not i["image_available"]],
            "missing_santali": [i["asset_id"] for i in items if not i["santali"]],
            "missing_hindi": [i["asset_id"] for i in items if not i["hindi"]],
            "uncategorised": [i["asset_id"] for i in items if i["asset_id"] not in in_decks],
        }


flashcard_image_library = FlashcardImageLibrary()
