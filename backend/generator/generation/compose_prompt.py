"""Prompt composition layer for bilingual FLN content generation.

Composes the authoritative base prompt, exactly one generation-type prompt,
and conditionally appends the Santali prompt whenever Santali output is required.
Replaces all placeholders across the composed prompt and verifies that no
placeholders remain unresolved.
"""
import argparse
import json
import os
import re
import sys
from typing import Any, Dict, List, Optional, Tuple

# Base directory paths
GEN_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(GEN_DIR)
MASTER_PATH = os.path.join(PROJECT_DIR, "canonical", "curriculum_master_v1.json")
BLUEPRINT_PATH = os.path.join(PROJECT_DIR, "blueprint", "content_blueprint_v1.json")
SCHEMA_PATH = os.path.join(GEN_DIR, "schema", "generated_content.schema.json")
PROMPTS_DIR = os.path.join(GEN_DIR, "prompts")


class BlueprintNotFoundError(KeyError):
    """Raised when a blueprint ID cannot be found in content_blueprint_v1."""


class CurriculumNotFoundError(KeyError):
    """Raised when a curriculum ID cannot be found in curriculum_master_v1."""


class InvalidPromptTypeError(ValueError):
    """Raised when a blueprint has an unsupported domain or language mode."""


class UnresolvedPlaceholderError(ValueError):
    """Raised when one or more {{PLACEHOLDER}} tags remain unresolved after composition."""


class ComposedPrompt:
    """Represents a fully composed, placeholder-resolved prompt ready for an LLM."""

    def __init__(
        self,
        text: str,
        content_id: str,
        blueprint_id: str,
        curriculum_id: str,
        prompt_stack: List[str],
        prompt_version: str,
        prompt_versions: Dict[str, str],
        language_mode: str,
        target_language: Optional[str],
        blueprint_record: Dict[str, Any],
        curriculum_record: Dict[str, Any],
    ):
        self.text = text
        self.content_id = content_id
        self.blueprint_id = blueprint_id
        self.curriculum_id = curriculum_id
        self.prompt_stack = prompt_stack
        self.prompt_version = prompt_version
        self.prompt_versions = prompt_versions
        self.language_mode = language_mode
        self.target_language = target_language
        self.blueprint_record = blueprint_record
        self.curriculum_record = curriculum_record

    def __str__(self) -> str:
        return self.text

    def to_dict(self) -> Dict[str, Any]:
        return {
            "content_id": self.content_id,
            "blueprint_id": self.blueprint_id,
            "curriculum_id": self.curriculum_id,
            "prompt_stack": self.prompt_stack,
            "prompt_version": self.prompt_version,
            "prompt_versions": self.prompt_versions,
            "language_mode": self.language_mode,
            "target_language": self.target_language,
            "text": self.text,
        }


class PromptComposer:
    """Loads blueprints, curriculum records, and prompt files to build composed prompts."""

    def __init__(
        self,
        master_path: str = MASTER_PATH,
        blueprint_path: str = BLUEPRINT_PATH,
        schema_path: str = SCHEMA_PATH,
        prompts_dir: str = PROMPTS_DIR,
    ):
        self.master_path = master_path
        self.blueprint_path = blueprint_path
        self.schema_path = schema_path
        self.prompts_dir = prompts_dir
        self._cache: Dict[str, Any] = {}

    def _load_json(self, path: str) -> Dict[str, Any]:
        with open(path, encoding="utf-8") as f:
            return json.load(f)

    @property
    def master(self) -> Dict[str, Any]:
        if "master" not in self._cache:
            m = self._load_json(self.master_path)
            self._cache["master"] = m
            self._cache["master_items"] = {r["canonical_id"]: r for r in m.get("curriculum", [])}
        return self._cache["master"]

    @property
    def blueprints(self) -> Dict[str, Any]:
        if "blueprints" not in self._cache:
            b = self._load_json(self.blueprint_path)
            self._cache["blueprints_doc"] = b
            self._cache["blueprints"] = {r["blueprint_id"]: r for r in b.get("blueprints", [])}
        return self._cache["blueprints"]

    @property
    def schema(self) -> Dict[str, Any]:
        if "schema" not in self._cache:
            self._cache["schema"] = self._load_json(self.schema_path)
        return self._cache["schema"]

    def get_blueprint(self, blueprint_id: str) -> Dict[str, Any]:
        bp = self.blueprints.get(blueprint_id)
        if bp is None:
            raise BlueprintNotFoundError(f"Blueprint {blueprint_id!r} not found in {os.path.basename(self.blueprint_path)}.")
        return bp

    def get_curriculum(self, curriculum_id: str) -> Dict[str, Any]:
        self.master  # ensure loaded
        mi = self._cache["master_items"].get(curriculum_id)
        if mi is None:
            raise CurriculumNotFoundError(f"Curriculum item {curriculum_id!r} not found in {os.path.basename(self.master_path)}.")
        return mi

    def get_prompt_text_and_version(self, prompt_name: str) -> Tuple[str, str]:
        path = os.path.join(self.prompts_dir, f"{prompt_name}.md")
        if not os.path.exists(path):
            raise FileNotFoundError(f"Prompt file not found: {path}")
        with open(path, encoding="utf-8") as f:
            content = f.read()
        m = re.search(r"^version:\s*(\S+)", content, re.MULTILINE)
        version = m.group(1) if m else "unknown"
        return content, version

    def select_prompt_stack(
        self, blueprint: Dict[str, Any], target_language: Optional[str] = None
    ) -> List[str]:
        domain = blueprint.get("domain")
        mode = blueprint.get("language_mode")

        if domain == "numeracy":
            if mode != "bilingual":
                raise InvalidPromptTypeError(f"Numeracy blueprints must use 'bilingual' mode; got {mode!r}.")
            stack = ["base_prompt", "numeracy_bilingual"]
            # Numeracy is bilingual (Hindi + Santali), so Santali output is always required
            stack.append("santali_generation")
            return stack

        elif domain == "literacy":
            if mode == "bilingual":
                stack = ["base_prompt", "literacy_bilingual"]
                # Bilingual literacy requires both Hindi and Santali
                stack.append("santali_generation")
                return stack
            elif mode == "parallel_monolingual":
                if not target_language:
                    raise ValueError("target_language ('hi' or 'sat') is required for parallel_monolingual literacy.")
                if target_language not in blueprint.get("language_pair", []):
                    raise ValueError(
                        f"target_language {target_language!r} is not in blueprint language_pair "
                        f"{blueprint.get('language_pair')}."
                    )
                stack = ["base_prompt", "literacy_parallel"]
                if target_language == "sat":
                    stack.append("santali_generation")
                return stack
            else:
                raise InvalidPromptTypeError(f"Unsupported literacy language_mode: {mode!r}.")

        else:
            raise InvalidPromptTypeError(f"Unsupported domain: {domain!r}.")

    def compose(
        self,
        blueprint_id: str,
        target_language: Optional[str] = None,
        extra_replacements: Optional[Dict[str, str]] = None,
    ) -> ComposedPrompt:
        bp = self.get_blueprint(blueprint_id)
        cid = bp.get("curriculum_id")
        curriculum = self.get_curriculum(cid)
        mode = bp.get("language_mode")

        # Determine target language and content_id
        if mode == "bilingual":
            lang_suffix = "bi"
            eff_target_lang = None
        elif mode == "parallel_monolingual":
            if not target_language:
                raise ValueError("target_language ('hi' or 'sat') is required for parallel_monolingual blueprints.")
            if target_language not in bp.get("language_pair", []):
                raise ValueError(
                    f"target_language {target_language!r} not in blueprint language_pair {bp.get('language_pair')}."
                )
            lang_suffix = target_language
            eff_target_lang = target_language
        else:
            raise InvalidPromptTypeError(f"Unknown language mode {mode!r}.")

        # GC-<grade>-<domain>-<outcome_num>-<seq>-<bi|hi|sat>-v1
        content_id = f"GC-{bp['blueprint_id'][3:]}-{lang_suffix}-v1"

        # Select prompt stack
        stack = self.select_prompt_stack(bp, target_language=eff_target_lang)

        # Load each prompt in the stack and record versions
        texts = []
        versions = {}
        for p_name in stack:
            text, version = self.get_prompt_text_and_version(p_name)
            texts.append(text)
            versions[p_name] = version

        prompt_version_str = "+".join(f"{p}@{versions[p]}" for p in stack)

        # Concatenate prompt sections deterministically
        composed_raw = "\n\n".join(texts)

        # Prepare replacement dictionary
        prototype_policy = self.master.get("prototype_policy", {})
        replacements = {
            "CONTENT_ID": content_id,
            "BLUEPRINT_ID": bp["blueprint_id"],
            "CURRICULUM_ID": cid,
            "LANGUAGE_MODE": mode,
            "TARGET_LANGUAGE": eff_target_lang or "",
            "BLUEPRINT_RECORD": json.dumps(bp, indent=2, ensure_ascii=False),
            "CURRICULUM_RECORD": json.dumps(curriculum, indent=2, ensure_ascii=False),
            "PROTOTYPE_POLICY": json.dumps(prototype_policy, indent=2, ensure_ascii=False),
            "GENERATED_CONTENT_SCHEMA": json.dumps(self.schema, indent=2, ensure_ascii=False),
        }
        if extra_replacements:
            replacements.update(extra_replacements)

        # Apply substitutions across the entire composed prompt
        composed_text = composed_raw
        for key, val in replacements.items():
            composed_text = composed_text.replace(f"{{{{{key}}}}}", str(val))

        # Check for any remaining unresolved placeholders
        unresolved = re.findall(r"\{\{([A-Za-z0-9_]+)\}\}", composed_text)
        if unresolved:
            raise UnresolvedPlaceholderError(
                f"Unresolved placeholder(s) in composed prompt: {sorted(set(unresolved))}."
            )

        return ComposedPrompt(
            text=composed_text,
            content_id=content_id,
            blueprint_id=bp["blueprint_id"],
            curriculum_id=cid,
            prompt_stack=stack,
            prompt_version=prompt_version_str,
            prompt_versions=versions,
            language_mode=mode,
            target_language=eff_target_lang,
            blueprint_record=bp,
            curriculum_record=curriculum,
        )


def compose_prompt(
    blueprint_id: str,
    target_language: Optional[str] = None,
    extra_replacements: Optional[Dict[str, str]] = None,
) -> ComposedPrompt:
    """Convenience functional interface for prompt composition."""
    composer = PromptComposer()
    return composer.compose(
        blueprint_id=blueprint_id,
        target_language=target_language,
        extra_replacements=extra_replacements,
    )


def main():
    ap = argparse.ArgumentParser(
        description="Compose bilingual FLN content generation prompt from a blueprint record."
    )
    ap.add_argument("--blueprint-id", "-b", required=True, help="Blueprint ID (e.g. BP-G1-NUM-032-01)")
    ap.add_argument(
        "--target-language",
        "-l",
        choices=["hi", "sat"],
        help="Target language for parallel_monolingual blueprints (hi or sat)",
    )
    ap.add_argument("--output", "-o", help="Write composed prompt to this file instead of stdout")
    ap.add_argument("--json-metadata", action="store_true", help="Print prompt metadata JSON to stderr")
    args = ap.parse_args()

    try:
        composed = compose_prompt(
            blueprint_id=args.blueprint_id, target_language=args.target_language
        )
    except (BlueprintNotFoundError, CurriculumNotFoundError, InvalidPromptTypeError, UnresolvedPlaceholderError, ValueError) as e:
        sys.stderr.write(f"ERROR: {e}\n")
        sys.exit(1)

    if args.json_metadata:
        meta = composed.to_dict()
        meta.pop("text", None)
        sys.stderr.write(json.dumps(meta, indent=2) + "\n")

    if args.output:
        os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(composed.text)
        print(f"Composed prompt written to {args.output}")
    else:
        sys.stdout.write(composed.text)


if __name__ == "__main__":
    main()
