"""Shared paths and config loading for the Santali flashcard pipeline."""
import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = ROOT / "config"
PAGES_DIR = ROOT / "pages"
RAW_DIR = ROOT / "raw"
IMAGES_DIR = ROOT / "images"
LABELS_DIR = ROOT / "labels"
METADATA_DIR = ROOT / "metadata"
FLASHCARDS_DIR = ROOT / "flashcards"
REPORTS_DIR = ROOT / "reports"


def load_pages_config():
    with open(CONFIG_DIR / "pages.yaml", encoding="utf-8") as f:
        return yaml.safe_load(f)


def load_taxonomy():
    with open(CONFIG_DIR / "taxonomy.json", encoding="utf-8") as f:
        return json.load(f)


def pdf_path(cfg):
    return ROOT / cfg["source"]["pdf"]


def category_info(taxonomy, category, subcategory=None):
    """Return the taxonomy node (id_prefix, folder, deck, label) for an asset."""
    node = taxonomy["categories"][category]
    if subcategory:
        node = node["subcategories"][subcategory]
    return node


def page_png(page_no):
    return PAGES_DIR / f"page_{page_no:02d}.png"


def load_assets():
    with open(METADATA_DIR / "assets.json", encoding="utf-8") as f:
        return json.load(f)


def save_metadata(data):
    """Write assets.json (full records) and assets.jsonl (one flat line per image)."""
    METADATA_DIR.mkdir(exist_ok=True)
    data["asset_count"] = len(data["assets"])
    (METADATA_DIR / "assets.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    with open(METADATA_DIR / "assets.jsonl", "w", encoding="utf-8") as f:
        for a in data["assets"]:
            f.write(json.dumps({
                "id": a["id"], "category": a["category"], "subcategory": a["subcategory"],
                "concept": a["concept"], "english": a["label"]["english"],
                "santali": a["label"]["santali"]["value"], "santali_verified": a["label"]["santali"]["verified"],
                "source_english": a["source_label"]["english"], "hindi": a["source_label"]["hindi"],
                "visual_type": a["visual_type"], "caption": a["caption"], "keywords": a["keywords"],
                "image": a["asset"]["path"], "source_crop": a["asset"]["source_crop"],
                "santali_label_image": a["label"]["santali"]["label_image"],
                "source_page": a["source"]["page"], "bbox": a["source"]["bbox"],
                **({"hex": a["hex"]} if "hex" in a else {}),
            }, ensure_ascii=False) + "\n")
