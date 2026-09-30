"""8-Unit Pilot Runner for Bilingual FLN Content Generation.

Orchestrates live or mock LLM generation for exactly the 8 defined pilot units:
1. BP-G1-LIT-001-01      (Grade 1 Literacy Bilingual)
2. BP-G1-LIT-011-01-hi   (Grade 1 Literacy Parallel, Hindi)
3. BP-G1-LIT-011-01-sat  (Grade 1 Literacy Parallel, Santali)
4. BP-G1-NUM-032-01      (Grade 1 Numeracy Bilingual)
5. BP-G2-LIT-001-01      (Grade 2 Literacy Bilingual)
6. BP-G2-LIT-013-01-sat  (Grade 2 Literacy Parallel, Santali)
7. BP-G2-NUM-018-01      (Grade 2 Numeracy Bilingual)
8. BP-G2-NUM-027-01      (Grade 2 Numeracy Bilingual)

Pipeline per unit:
  Blueprint Spec
        ↓
  PromptComposer
        ↓
  MockProvider (offline)
        ↓
  JSON Parsing
        ↓
  Schema Validation
        ↓
  Content Validation
        ↓
  Atomic File Output
        ↓
  ReviewManager (status: 'pending')
        ↓
  ManifestManager (sync state)
"""
import argparse
import os
import sys
from typing import List, Optional, Tuple

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

# Setup pathing
HERE = os.path.dirname(os.path.abspath(__file__))
GEN_DIR = os.path.dirname(HERE)
PROJECT_DIR = os.path.dirname(GEN_DIR)
for p in [PROJECT_DIR, GEN_DIR, HERE, os.path.join(GEN_DIR, "validation")]:
    if p not in sys.path:
        sys.path.insert(0, p)

from compose_prompt import PromptComposer
from manifest.manifest_manager import ManifestManager
from orchestrator import GenerationOrchestrator, GenerationResult
from providers.base import LLMProvider
from providers.mock import MockProvider
from review.review_manager import ReviewManager

PILOT_UNITS: List[str] = [
    "BP-G1-LIT-001-01",
    "BP-G1-LIT-011-01-hi",
    "BP-G1-LIT-011-01-sat",
    "BP-G1-NUM-032-01",
    "BP-G2-LIT-001-01",
    "BP-G2-LIT-013-01-sat",
    "BP-G2-NUM-018-01",
    "BP-G2-NUM-027-01",
]


def parse_unit_spec(spec: str) -> Tuple[str, Optional[str]]:
    """Parse a unit spec into blueprint_id and target_language.

    Examples:
        'BP-G1-LIT-001-01' -> ('BP-G1-LIT-001-01', None)
        'BP-G1-LIT-011-01-hi' -> ('BP-G1-LIT-011-01', 'hi')
        'BP-G1-LIT-011-01-sat' -> ('BP-G1-LIT-011-01', 'sat')
    """
    if spec.endswith("-hi"):
        return spec[:-3], "hi"
    elif spec.endswith("-sat"):
        return spec[:-4], "sat"
    return spec, None


def run_pilot(
    units: Optional[List[str]] = None,
    provider_name: str = "mock",
    dry_run: bool = False,
    force: bool = False,
    model: Optional[str] = None,
    output_dir: Optional[str] = None,
) -> bool:
    """Execute the pilot generation run.

    Args:
        units: List of unit specs to run. Defaults to PILOT_UNITS.
        provider_name: Content-generation provider to use ('mock').
        dry_run: If True, uses MockProvider instead of real providers.
        force: If True, overwrites existing output files.
        model: Model identifier override.
        output_dir: Output directory override.

    Returns:
        True if all attempted units succeeded, False otherwise.
    """
    target_units = units or PILOT_UNITS
    total_units = len(target_units)

    effective_provider = "mock" if dry_run else provider_name
    print("=" * 60)
    print("PILOT GENERATION START")
    print(f"Target units count: {total_units}")
    print(f"Provider: {effective_provider.upper()}")
    print("=" * 60)

    # Initialize managers
    review_manager = ReviewManager()
    manifest_manager = ManifestManager(review_manager=review_manager)

    # Initialize provider. The cloud providers were removed with the external
    # AI stack, so the offline MockProvider is the only one available.
    if effective_provider != "mock":
        print(
            f"\n[FATAL] Provider '{effective_provider}' is not available. "
            "This build is fully offline; only the 'mock' provider remains."
        )
        return False
    provider: LLMProvider = MockProvider(mode="valid")

    orchestrator = GenerationOrchestrator(
        provider=provider,
        review_manager=review_manager,
        output_dir=output_dir,
    )

    attempted = 0
    generated = 0
    machine_valid = 0
    failed = 0
    review_pending = 0

    results: List[GenerationResult] = []

    for idx, spec in enumerate(target_units, start=1):
        attempted += 1
        blueprint_id, target_lang = parse_unit_spec(spec)
        lang_str = f" [{target_lang}]" if target_lang else ""
        print(f"\n[{idx}/{total_units}] {spec}{lang_str} ...")

        result = orchestrator.generate(
            blueprint_id=blueprint_id,
            target_language=target_lang,
            force=force,
        )
        results.append(result)

        if result.is_success:
            generated += 1
            machine_valid += 1
            review_pending += 1

            # Update manifest
            manifest_manager.register_from_orchestrator(
                result=result,
                model_parameters={"model": getattr(provider, "model", "mock")},
            )
            manifest_manager.sync_review(result.content_id)
            manifest_manager.save()

            print(f"  [OK] generated")
            print(f"  [OK] schema valid")
            print(f"  [OK] content valid")
            print(f"  -> output: {result.output_path}")
            print(f"  -> review pending: {result.review_record_path}")
        else:
            failed += 1
            # If content_id exists, record failure in manifest
            if result.content_id and manifest_manager.get_entry(result.content_id):
                manifest_manager.register_from_orchestrator(
                    result=result,
                    check_file_exists=False,
                )
                manifest_manager.save()

            print(f"  [FAIL] ({result.status})")
            for err in result.errors[:3]:
                print(f"    - {err}")
            if len(result.errors) > 3:
                print(f"    - ... and {len(result.errors) - 3} more errors")

    print("\n" + "=" * 60)
    print("PILOT COMPLETE")
    print(f"Attempted:      {attempted}")
    print(f"Generated:      {generated}")
    print(f"Machine-valid:  {machine_valid}")
    print(f"Failed:         {failed}")
    print(f"Review pending: {review_pending}")
    print("=" * 60)

    return failed == 0


def main():
    parser = argparse.ArgumentParser(description="Run 8-unit bilingual FLN pilot generation.")
    parser.add_argument(
        "--provider",
        choices=["mock"],
        default="mock",
        help="Content-generation provider (only the offline mock provider remains)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Use MockProvider to test runner execution without calling live APIs.",
    )
    parser.add_argument(
        "--unit",
        type=str,
        help="Run only a single specific unit spec (e.g. BP-G1-NUM-032-01 or BP-G1-LIT-011-01-hi).",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing generated output files.",
    )
    parser.add_argument(
        "--model",
        type=str,
        default=None,
        help="Model identifier override (unused by the mock provider).",
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default=None,
        help="Directory to save generated JSON files.",
    )
    args = parser.parse_args()

    units = [args.unit] if args.unit else None
    success = run_pilot(
        units=units,
        provider_name=args.provider,
        dry_run=args.dry_run,
        force=args.force,
        model=args.model,
        output_dir=args.output_dir,
    )
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
