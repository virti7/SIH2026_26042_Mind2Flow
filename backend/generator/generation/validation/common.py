"""Shared helpers for the generation validators."""
import hashlib
import json
import os

VALIDATOR_VERSION = "1.0.0"

GEN_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PROJECT_DIR = os.path.abspath(os.path.join(GEN_DIR, ".."))
MASTER_PATH = os.path.join(PROJECT_DIR, "canonical", "curriculum_master_v1.json")
BLUEPRINT_PATH = os.path.join(PROJECT_DIR, "blueprint", "content_blueprint_v1.json")
SCHEMA_PATH = os.path.join(GEN_DIR, "schema", "generated_content.schema.json")

COUNT_KEYS = ("cards", "questions", "words", "story_cards", "objects", "pictures")
LANGS = ("hi", "sat")


def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


_cache = {}


def master():
    if "master" not in _cache:
        m = load_json(MASTER_PATH)
        _cache["master"] = m
        _cache["master_ids"] = {r["canonical_id"]: r for r in m["curriculum"]}
    return _cache["master"]


def master_item(cid):
    master()
    return _cache["master_ids"].get(cid)


def blueprints():
    if "bp" not in _cache:
        b = load_json(BLUEPRINT_PATH)
        _cache["bp_doc"] = b
        _cache["bp"] = {r["blueprint_id"]: r for r in b["blueprints"]}
    return _cache["bp"]


def blueprint(bid):
    return blueprints().get(bid)


def expected_count(bp):
    """(key, value) of the item-count constraint for a blueprint, or (None, None)."""
    c = bp["generation_constraints"]
    for k in COUNT_KEYS:
        if k in c:
            return k, c[k]
    return None, None


def iter_localized(obj, path="$"):
    """Yield (json_path, localized_dict) for every language object in a content unit.
    A language object is a dict whose keys are all language codes with string values."""
    if isinstance(obj, dict):
        if obj and set(obj) <= set(LANGS) and all(isinstance(v, str) for v in obj.values()):
            yield path, obj
            return
        for k, v in obj.items():
            if k in ("description_en", "scripts"):  # metadata, not learner-facing text
                continue
            yield from iter_localized(v, f"{path}.{k}")
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from iter_localized(v, f"{path}[{i}]")


class Report:
    def __init__(self, validator, content_id=None):
        self.validator = validator
        self.content_id = content_id
        self.errors, self.warnings, self.info = [], [], []

    def error(self, code, msg, where=None):
        self.errors.append({"code": code, "message": msg, "where": where})

    def warn(self, code, msg, where=None):
        self.warnings.append({"code": code, "message": msg, "where": where})

    def note(self, code, msg, where=None):
        self.info.append({"code": code, "message": msg, "where": where})

    def merge(self, other):
        self.errors += other.errors
        self.warnings += other.warnings
        self.info += other.info

    @property
    def ok(self):
        return not self.errors

    def to_dict(self):
        return {"validator": self.validator, "validator_version": VALIDATOR_VERSION, "content_id": self.content_id,
                "passed": self.ok, "errors": self.errors, "warnings": self.warnings, "info": self.info}
