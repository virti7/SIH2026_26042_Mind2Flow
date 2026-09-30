"""Create generation_manifest.json (once). Lists every planned content unit with the exact
versions/hashes of the curriculum, blueprint, schema, prompts and validators it will be built from.

Update entries in place as units are generated (status, model, timestamp, hashes). If a provisional
curriculum decision changes, find affected units via `conflict_refs` and mark them `stale`.
"""
import glob
import hashlib
import json
import os
import re
import sys

GEN = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ROOT = os.path.dirname(GEN)
OUT = os.path.join(GEN, "manifest", "generation_manifest.json")
if os.path.exists(OUT):
    sys.exit(f"{OUT} exists; edit it instead of re-initialising.")


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def rel(p):
    return os.path.relpath(p, ROOT).replace("\\", "/")


def prompt_version(p):
    m = re.search(r"^version:\s*(\S+)", open(p, encoding="utf-8").read(), re.M)
    return m.group(1) if m else None


master_p = os.path.join(ROOT, "canonical", "curriculum_master_v1.json")
bp_p = os.path.join(ROOT, "blueprint", "content_blueprint_v1.json")
schema_p = os.path.join(GEN, "schema", "generated_content.schema.json")
prompts = {os.path.splitext(os.path.basename(p))[0]: p for p in sorted(glob.glob(os.path.join(GEN, "prompts", "*.md")))}
validators = sorted(glob.glob(os.path.join(GEN, "validation", "*.py")))
sys.path.insert(0, os.path.join(GEN, "validation"))
from common import VALIDATOR_VERSION  # noqa: E402

bp = json.load(open(bp_p, encoding="utf-8"))


def prompt_stack(b, lang):
    kind = ("numeracy_bilingual" if b["domain"] == "numeracy"
            else "literacy_parallel" if b["language_mode"] == "parallel_monolingual" else "literacy_bilingual")
    stack = ["base_prompt", kind]
    if lang in ("sat", "bi"):
        stack.append("santali_generation")
    return stack


entries = []
for b in bp["blueprints"]:
    langs = ["bi"] if b["language_mode"] == "bilingual" else list(b["language_pair"])
    for l in langs:
        stack = prompt_stack(b, l)
        entries.append({
            "content_id": f"GC-{b['blueprint_id'][3:]}-{l}-v1",
            "blueprint_id": b["blueprint_id"],
            "curriculum_id": b["curriculum_id"],
            "grade": b["grade"],
            "domain": b["domain"],
            "content_type": b["content_type"],
            "languages": b["language_pair"] if l == "bi" else [l],
            "curriculum_version": "curriculum_master_v1",
            "blueprint_version": "content_blueprint_v1",
            "prompt_stack": stack,
            "prompt_version": "+".join(f"{p}@{prompt_version(prompts[p])}" for p in stack),
            "model": None,
            "model_parameters": None,
            "generation_timestamp": None,
            "generation_status": "planned",
            "output_path": f"generation/generated/pilot_v1/GC-{b['blueprint_id'][3:]}-{l}-v1.json",
            "content_sha256": None,
            "validator_version": None,
            "validation_passed": None,
            "validation_report_path": None,
            "review_status": "pending",
            "provisional": b["provisional"],
            "conflict_refs": b["conflict_refs"],
            "superseded_by": None,
            "notes": [],
        })

manifest = {
    "manifest_version": "generation_manifest_v1",
    "batch": "pilot_v1",
    "inputs": {
        "curriculum_master": {"path": rel(master_p), "version": "curriculum_master_v1", "sha256": sha(master_p)},
        "content_blueprint": {"path": rel(bp_p), "version": "content_blueprint_v1", "sha256": sha(bp_p)},
        "schema": {"path": rel(schema_p), "version": "generated_content_v1", "sha256": sha(schema_p)},
        "prompts": {k: {"path": rel(p), "version": prompt_version(p), "sha256": sha(p)} for k, p in prompts.items()},
        "validators": {"version": VALIDATOR_VERSION, "files": {os.path.basename(v): sha(v) for v in validators}},
    },
    "status_values": {
        "generation_status": ["planned", "generated", "failed", "validated", "rejected", "stale"],
        "review_status": ["pending", "in_review", "changes_requested", "approved", "rejected"],
    },
    "rules": [
        "One entry per content unit. Bilingual blueprints -> one '-bi-' unit; parallel_monolingual blueprints -> one '-hi-' and one '-sat-' unit.",
        "Fill model, model_parameters, generation_timestamp and content_sha256 when a unit is generated; validator fields when validated.",
        "Regenerating a unit creates -v2 and sets superseded_by on the old entry; never overwrite a generated file.",
        "If a provisional decision (conflict_refs) changes, mark affected entries 'stale' and regenerate.",
    ],
    "summary": {"blueprints": len(bp["blueprints"]), "planned_units": len(entries),
                "bilingual_units": sum(e["content_id"].split("-")[-2] == "bi" for e in entries),
                "parallel_units": sum(e["content_id"].split("-")[-2] != "bi" for e in entries)},
    "entries": entries,
}
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
print(json.dumps(manifest["summary"]))
