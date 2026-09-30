"""Generation orchestrator connecting prompt composition, LLM providers, and validation."""
import argparse
import json
import os
import sys
import tempfile
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

# Setup pathing to allow sibling imports when run as script or module
HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(HERE)
if PROJECT_DIR not in sys.path:
    sys.path.insert(0, PROJECT_DIR)
if HERE not in sys.path:
    sys.path.insert(0, HERE)
VALIDATION_DIR = os.path.join(HERE, "validation")
if VALIDATION_DIR not in sys.path:
    sys.path.insert(0, VALIDATION_DIR)

from compose_prompt import PromptComposer, ComposedPrompt, BlueprintNotFoundError, CurriculumNotFoundError
from providers.base import LLMProvider
from content_validator import schema_validator, validate_unit

DEFAULT_OUTPUT_DIR = os.path.join(HERE, "generated", "pilot_v1")


@dataclass
class GenerationResult:
    """Structured result of a generation pipeline execution."""
    blueprint_id: str
    content_id: Optional[str] = None
    status: str = "success"  # success, provider_error, json_error, schema_error, content_validation_error, file_exists_error, composer_error
    provider_used: str = ""
    validation_status: Optional[str] = None
    output_path: Optional[str] = None
    errors: List[Any] = field(default_factory=list)
    warnings: List[Any] = field(default_factory=list)
    data: Optional[Dict[str, Any]] = None
    review_status: Optional[str] = None
    review_record_path: Optional[str] = None

    @property
    def is_success(self) -> bool:
        return self.status == "success"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "blueprint_id": self.blueprint_id,
            "content_id": self.content_id,
            "status": self.status,
            "provider_used": self.provider_used,
            "validation_status": self.validation_status,
            "output_path": self.output_path,
            "review_status": self.review_status,
            "review_record_path": self.review_record_path,
            "errors": self.errors,
            "warnings": self.warnings,
        }


class GenerationOrchestrator:
    """Orchestrates FLN content generation from blueprint to atomic output.
    
    Flow:
        blueprint_id (+ target_language)
            ↓
        PromptComposer
            ↓
        composed prompt
            ↓
        provider.generate(prompt)
            ↓
        raw response
            ↓
        JSON parsing
            ↓
        JSON Schema validation
            ↓
        content validation
            ↓
        atomic write
    """

    def __init__(
        self,
        provider: LLMProvider,
        output_dir: Optional[str] = None,
        composer: Optional[PromptComposer] = None,
        review_manager: Optional[Any] = None,
    ):
        if not isinstance(provider, LLMProvider):
            raise TypeError(f"provider must implement LLMProvider; got {type(provider)}")
        self.provider = provider
        self.output_dir = os.path.abspath(output_dir or DEFAULT_OUTPUT_DIR)
        self.composer = composer or PromptComposer()
        self.schema_validator = schema_validator()
        self.review_manager = review_manager

    def _atomic_write_json(self, target_path: str, data: Dict[str, Any]) -> None:
        """Write JSON data to a temporary file and atomically replace the target path."""
        dir_name = os.path.dirname(os.path.abspath(target_path))
        os.makedirs(dir_name, exist_ok=True)
        
        # mkstemp in the same directory guarantees the same filesystem for atomic rename
        fd, temp_path = tempfile.mkstemp(dir=dir_name, prefix=".tmp_gen_")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
                f.flush()
                os.fsync(f.fileno())
            os.replace(temp_path, target_path)
        except Exception:
            if os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError:
                    pass
            raise

    def generate(
        self,
        blueprint_id: str,
        target_language: Optional[str] = None,
        force: bool = False,
    ) -> GenerationResult:
        """Execute the full generation and validation pipeline for one blueprint unit.

        Args:
            blueprint_id: The blueprint ID to generate content for.
            target_language: Target language ('hi' or 'sat') for parallel_monolingual blueprints.
            force: If True, overwrite an existing output file. Otherwise fail with file_exists_error.

        Returns:
            GenerationResult describing the outcome.
        """
        # If blueprint_id has a -hi or -sat suffix and target_language is not set, parse it
        if target_language is None:
            if blueprint_id.endswith("-hi"):
                blueprint_id, target_language = blueprint_id[:-3], "hi"
            elif blueprint_id.endswith("-sat"):
                blueprint_id, target_language = blueprint_id[:-4], "sat"

        provider_name = self.provider.__class__.__name__

        # 1. Compose the prompt
        try:
            composed = self.composer.compose(
                blueprint_id=blueprint_id,
                target_language=target_language,
            )
        except (BlueprintNotFoundError, CurriculumNotFoundError, ValueError) as e:
            return GenerationResult(
                blueprint_id=blueprint_id,
                status="composer_error",
                provider_used=provider_name,
                errors=[str(e)],
            )

        content_id = composed.content_id
        target_filename = f"{content_id}.json"
        target_path = os.path.join(self.output_dir, target_filename)

        # 2. Check if output already exists (unless force is requested)
        if os.path.exists(target_path) and not force:
            return GenerationResult(
                blueprint_id=blueprint_id,
                content_id=content_id,
                status="file_exists_error",
                provider_used=provider_name,
                output_path=target_path,
                errors=[f"Target file already exists at {target_path}. Pass force=True to overwrite."],
            )

        # 3. Call the provider
        try:
            raw_response = self.provider.generate(composed.text)
        except Exception as e:
            return GenerationResult(
                blueprint_id=blueprint_id,
                content_id=content_id,
                status="provider_error",
                provider_used=provider_name,
                errors=[f"Provider {provider_name} failed: {e}"],
            )

        # 4. Parse JSON
        if not isinstance(raw_response, str) or not raw_response.strip():
            return GenerationResult(
                blueprint_id=blueprint_id,
                content_id=content_id,
                status="json_error",
                provider_used=provider_name,
                errors=["Provider returned an empty response or non-string object."],
            )

        try:
            data = json.loads(raw_response)
        except json.JSONDecodeError as e:
            return GenerationResult(
                blueprint_id=blueprint_id,
                content_id=content_id,
                status="json_error",
                provider_used=provider_name,
                errors=[f"Failed to parse model response as JSON: {e}"],
            )

        if not isinstance(data, dict):
            return GenerationResult(
                blueprint_id=blueprint_id,
                content_id=content_id,
                status="json_error",
                provider_used=provider_name,
                errors=["Parsed JSON is not an object/dictionary."],
            )

        # 5. Schema validation
        schema_errs = list(self.schema_validator.iter_errors(data))
        if schema_errs:
            formatted_errors = [
                f"Schema error at $.{'.'.join(str(p) for p in err.path)}: {err.message}"
                for err in sorted(schema_errs, key=lambda e: list(e.path))
            ]
            return GenerationResult(
                blueprint_id=blueprint_id,
                content_id=data.get("content_id") or content_id,
                status="schema_error",
                provider_used=provider_name,
                validation_status="FAILED",
                errors=formatted_errors,
                data=data,
            )

        # 6. Content validation
        rep = validate_unit(data)
        if not rep.ok:
            return GenerationResult(
                blueprint_id=blueprint_id,
                content_id=data.get("content_id") or content_id,
                status="content_validation_error",
                provider_used=provider_name,
                validation_status="FAILED",
                errors=rep.errors,
                warnings=rep.warnings,
                data=data,
            )

        # 7. Atomic output persistence
        actual_content_id = data.get("content_id") or content_id
        final_path = os.path.join(self.output_dir, f"{actual_content_id}.json")
        try:
            self._atomic_write_json(final_path, data)
        except Exception as e:
            return GenerationResult(
                blueprint_id=blueprint_id,
                content_id=actual_content_id,
                status="io_error",
                provider_used=provider_name,
                validation_status="PASSED",
                errors=[f"Failed to atomically write output file: {e}"],
                data=data,
            )

        # 8. Human review record creation (if review_manager is injected)
        review_status = None
        review_path = None
        if self.review_manager is not None:
            try:
                rec = self.review_manager.create_review_record(
                    content=data,
                    content_path=final_path,
                    validation_report={
                        "validator_version": "1.0.0",
                        "passed": True,
                        "warnings": len(rep.warnings),
                        "report_path": final_path,
                    },
                )
                review_status = rec.get("review_status")
                review_path = self.review_manager.get_record_path(actual_content_id)
            except Exception as e:
                rep.warnings.append(f"Failed to create review record: {e}")

        return GenerationResult(
            blueprint_id=blueprint_id,
            content_id=actual_content_id,
            status="success",
            provider_used=provider_name,
            validation_status="PASSED",
            output_path=final_path,
            warnings=rep.warnings,
            data=data,
            review_status=review_status,
            review_record_path=review_path,
        )


def main():
    ap = argparse.ArgumentParser(
        description="Bilingual FLN Content Generation Orchestrator."
    )
    ap.add_argument("--blueprint-id", "-b", required=True, help="Blueprint ID (e.g. BP-G1-NUM-032-01)")
    ap.add_argument(
        "--target-language",
        "-l",
        choices=["hi", "sat"],
        help="Target language for parallel_monolingual blueprints (hi or sat)",
    )
    ap.add_argument(
        "--provider",
        choices=["mock"],
        default="mock",
        help="Content-generation provider (only the offline mock provider remains).",
    )
    ap.add_argument(
        "--model",
        help="Model identifier override (unused by the mock provider).",
    )
    ap.add_argument(
        "--mock-mode",
        choices=["valid", "invalid_json", "schema_invalid", "content_invalid"],
        default="valid",
        help="Response mode for MockProvider (default: valid)",
    )
    ap.add_argument("--output-dir", "-o", help="Directory for generated output")
    ap.add_argument("--force", action="store_true", help="Overwrite existing generated output")
    ap.add_argument("--create-review", action="store_true", help="Create a pending review record upon successful generation")
    ap.add_argument("--json", action="store_true", help="Output result as JSON")
    args = ap.parse_args()

    # Instantiate provider based on CLI arguments. The cloud providers were
    # removed with the external AI stack, so only the offline mock remains.
    from providers.mock import MockProvider

    provider = MockProvider(mode=args.mock_mode)

    review_mgr = None
    if args.create_review:
        from review.review_manager import ReviewManager
        review_mgr = ReviewManager()

    orchestrator = GenerationOrchestrator(
        provider=provider,
        output_dir=args.output_dir,
        review_manager=review_mgr,
    )

    result = orchestrator.generate(
        blueprint_id=args.blueprint_id,
        target_language=args.target_language,
        force=args.force,
    )

    if args.json:
        print(json.dumps(result.to_dict(), indent=2))
    else:
        status_symbol = "SUCCESS" if result.is_success else "FAILED"
        print(f"[{status_symbol}] {result.blueprint_id} ({result.content_id or 'N/A'})")
        print(f"  Status: {result.status}")
        print(f"  Provider: {result.provider_used}")
        if result.output_path:
            print(f"  Output: {result.output_path}")
        if result.review_status:
            print(f"  Review: {result.review_status} ({result.review_record_path})")
        if result.errors:
            print("  Errors:")
            for err in result.errors:
                print(f"    - {err}")
        if result.warnings:
            print(f"  Warnings: {len(result.warnings)}")

    sys.exit(0 if result.is_success else 1)


if __name__ == "__main__":
    main()
