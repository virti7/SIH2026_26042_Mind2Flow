# Bilingual FLN Content Generation Pipeline

A reproducible, schema-validated content generation pipeline for Foundational Literacy and Numeracy (FLN) targeting primary school children in Grades 1 and 2 (ages 6–7) in Hindi (`hi`) and Santali (`sat`).

## Overview

The pipeline generates pedagogically sound, culturally appropriate educational content (flashcards, worksheets, interactive activities, and audio activities) grounded in a frozen canonical curriculum and a 35-seed content blueprint.

### Scope
- **Target Grades:** Grade 1 and Grade 2.
- **Domains:** Foundational Literacy & Foundational Numeracy.
- **Languages:** Primary pair Hindi (Devanagari script) and Santali (Ol Chiki script default).
- **Out of Scope for Prototype:** Grade 3 content, L2 English-only seeds, timed reading (WPM), multiplication tables, fractions beyond "half", and paragraph writing.

---

## Requirements & Python Version

- **Python Version:** Python 3.10 or higher (compatible with Python 3.10 – 3.14).
- **Core Dependencies:** Listed in `requirements.txt`.

---

## Installation

Create a virtual environment (recommended) and install the dependencies:

```bash
cd "d:\1SIH_JHARH\bilingual generator"
python -m venv .venv
# On Windows:
.venv\Scripts\activate
# On Unix/macOS:
source .venv/bin/activate

pip install -r requirements.txt
```

---

## Directory Structure

```text
bilingual generator/
├── canonical/
│   └── curriculum_master_v1.json          # Frozen canonical curriculum master dataset (229 items)
├── blueprint/
│   └── content_blueprint_v1.json          # 35-unit content blueprint derived from canonical items
├── review/
│   └── conflicts_to_review.json           # Catalog of unresolved source curriculum conflicts
├── raw/                                   # Stage 1 source extraction documents and inventory
│   ├── 1_source_inventory.json
│   ├── 2_curriculum_items.json
│   ├── 3_implementation_mapping.json
│   ├── 4_coverage_summary.json
│   ├── 5_gaps_and_uncertainties.json
│   └── fln_curriculum_dataset.json
├── generation/
│   ├── __init__.py
│   ├── schema/
│   │   └── generated_content.schema.json  # Draft 2020-12 schema for generated content units
│   ├── prompts/
│   │   ├── base_prompt.md                 # Base prompt with authority rules and placeholders
│   │   ├── literacy_bilingual.md          # Domain prompt for bilingual literacy units
│   │   ├── literacy_parallel.md           # Domain prompt for parallel monolingual literacy
│   │   ├── numeracy_bilingual.md          # Domain prompt for bilingual numeracy units
│   │   └── santali_generation.md          # Santali-specific orthography & Ol Chiki rules
│   ├── validation/
│   │   ├── __init__.py
│   │   ├── common.py                      # Shared helpers, report dataclass, and caching
│   │   ├── content_validator.py           # Main entry point: schema, blueprint & exclusion checks
│   │   ├── language_validator.py          # Script detection (Devanagari, Ol Chiki) & language checks
│   │   ├── numeracy_validator.py          # Mathematical verification & grade range bounds
│   │   └── tests/
│   │       ├── __init__.py
│   │       ├── fixtures/
│   │       │   ├── valid_literacy_parallel_hi.json
│   │       │   └── valid_numeracy_bilingual.json
│   │       └── run_tests.py               # Unit and regression test suite for validators
│   ├── review/
│   │   └── review_schema.json             # Schema for human review records and gate signoffs
│   ├── manifest/
│   │   ├── __init__.py
│   │   ├── generation_manifest.json       # Deterministic manifest tracking all 46 planned units
│   │   └── init_manifest.py               # One-time initialization script for generation manifest
│   └── generated/
│       └── pilot_v1/                      # Target directory for generated content units
├── requirements.txt                       # Declared third-party dependencies
└── README.md                              # This documentation
```

---

## Operational Commands

### 1. Run Validator Test Suite

Executes all self-tests and mutation tests across schemas, blueprints, numeracy rules, and language validators:

```bash
python generation/validation/tests/run_tests.py
```

### 2. Validate Generated Content

Validates a single JSON content file or a directory containing generated content units (`GC-*.json`):

```bash
# Validate a single content file:
python generation/validation/content_validator.py generation/validation/tests/fixtures/valid_numeracy_bilingual.json

# Validate a directory of generated units and export a JSON report:
python generation/validation/content_validator.py generation/generated/pilot_v1 --report report.json
```

**Exit Codes:**
- `0`: All inspected units passed validation (warnings permitted).
- `1`: At least one unit failed validation.

### 3. Initialize or Inspect Generation Manifest

Initializes `generation_manifest.json` from `content_blueprint_v1.json`, expanding the 35 blueprints into 46 planned generation units (24 bilingual + 22 parallel monolingual) with input SHA256 hashes:

```bash
python generation/manifest/init_manifest.py
```

*Note: If `generation_manifest.json` already exists, `init_manifest.py` exits with an informative message to prevent accidental overwriting.*

---

## Content Generation & Pilot Execution

### Windows UTF-8 Output

When printing composed prompts or content containing Ol Chiki (`sat`) characters directly to the Windows console, specify `-X utf8` to prevent `cp1252` encoding errors:

```powershell
python -X utf8 generation/compose_prompt.py -b BP-G1-NUM-032-01 --json-metadata
```

Alternatively, set the environment variable:
```powershell
$env:PYTHONIOENCODING="utf-8"
```

### Orchestrator Provider Selection

The orchestrator supports `mock`, `gemini`, `grok`, and `sarvam` providers via CLI:

```bash
# Deterministic mock generation:
python generation/orchestrator.py --blueprint-id BP-G1-NUM-032-01 --provider mock --mock-mode valid

# Real Gemini generation (requires $env:GEMINI_API_KEY):
python generation/orchestrator.py --blueprint-id BP-G1-NUM-032-01 --provider gemini

# Production-ready Sarvam AI generation (requires $env:SARVAM_API_KEY):
python generation/orchestrator.py --blueprint-id BP-G1-NUM-032-01 --provider sarvam
python -m generation.orchestrator --blueprint-id BP-G1-NUM-032-01 --provider sarvam
```

### Sarvam AI Provider Details
- **Model**: Default `sarvam-105b` (override via `--model` or `$env:SARVAM_MODEL`).
- **SDK**: Official `sarvamai` Python SDK (`from sarvamai import SarvamAI`).
- **Authentication**: Set `$env:SARVAM_API_KEY="<YOUR_KEY>"`. Never hardcoded or logged.
- **Structured Output**: Uses official Sarvam Chat Completion V1 with `response_format` JSON schema matching `generated_content.schema.json`.
- **Validation Flow**: Output is parsed with `json.loads()`, verified against JSON Schema Draft 2020-12, passed through pedagogical & numeracy validators, atomically written to disk, and registered with a pending human review record.
- **Hindi + Santali Review Gates**: Successful LLM generation does not bypass human review. Santali script unconfirmed gates (`LANG_SAT_SCRIPT_UNCONFIRMED`) and answer key verification remain strictly enforced before content can be published.
- **Known Limitations**: LLM-generated Santali orthography and math operand caps must be verified by human reviewers; network timeouts/rate limits are automatically retried with exponential backoff up to 3 times.

### Running the 8-Unit Pilot

```bash
# Dry run with MockProvider (offline):
python generation/pilot/run_pilot.py --dry-run

# Live generation with SarvamProvider (requires $env:SARVAM_API_KEY):
$env:SARVAM_API_KEY="YOUR_KEY"
python generation/pilot/run_pilot.py --provider sarvam

# Live generation with GeminiProvider (requires $env:GEMINI_API_KEY):
$env:GEMINI_API_KEY="YOUR_KEY"
python generation/pilot/run_pilot.py --provider gemini
```
