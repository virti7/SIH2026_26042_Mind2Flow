"""Deterministic mock LLM provider for local testing and validation."""
import os
from typing import Optional

from .base import LLMProvider

DEFAULT_FIXTURES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures")

MODE_DEFAULT_FILES = {
    "valid": "valid_numeracy_bilingual.json",
    "valid_flashcard": "valid_flashcard_bilingual.json",
    "invalid_json": "invalid_json.txt",
    "schema_invalid": "schema_invalid.json",
    "content_invalid": "content_invalid.json",
}


class MockProvider(LLMProvider):
    """Mock LLM provider that returns deterministic responses from fixture files.
    
    Attributes:
        mode: The active mock mode ('valid', 'valid_flashcard', 'invalid_json', 'schema_invalid', 'content_invalid').
        fixture_path: Explicit override path to a fixture file.
        fixtures_dir: Base directory containing default mode fixtures.
        call_count: Number of times generate() has been invoked.
        last_prompt: The prompt string received in the most recent generate() call.
    """

    def __init__(
        self,
        mode: str = "valid",
        fixture_path: Optional[str] = None,
        fixtures_dir: Optional[str] = None,
    ):
        self.fixtures_dir = fixtures_dir or DEFAULT_FIXTURES_DIR
        self.call_count = 0
        self.last_prompt: Optional[str] = None
        self.fixture_path: Optional[str] = None
        self.set_mode(mode=mode, fixture_path=fixture_path)

    def set_mode(self, mode: str, fixture_path: Optional[str] = None) -> None:
        """Set the mock mode and optional explicit fixture path."""
        if mode not in MODE_DEFAULT_FILES:
            raise ValueError(
                f"Unknown mock mode: {mode!r}. Supported modes: {sorted(MODE_DEFAULT_FILES.keys())}"
            )
        self.mode = mode
        self.fixture_path = fixture_path

    def _resolve_fixture_path(self, prompt: Optional[str] = None) -> str:
        """Determine the absolute path to the fixture file to read."""
        if self.fixture_path:
            return os.path.abspath(self.fixture_path)
        if self.mode == "valid" and prompt:
            prompt_lower = prompt.lower()
            if 'content_type": "flashcard"' in prompt_lower or "bp-g1-num-041-01" in prompt_lower:
                return os.path.join(self.fixtures_dir, "valid_flashcard_bilingual.json")
        filename = MODE_DEFAULT_FILES[self.mode]
        return os.path.join(self.fixtures_dir, filename)

    def generate(self, prompt: str) -> str:
        """Simulate LLM generation by recording the prompt and returning fixture content."""
        self.call_count += 1
        self.last_prompt = prompt

        path = self._resolve_fixture_path(prompt)
        if not os.path.exists(path):
            raise FileNotFoundError(f"Mock fixture file not found: {path}")

        with open(path, "r", encoding="utf-8") as f:
            return f.read()

    def reset(self) -> None:

        """Reset invocation metrics."""
        self.call_count = 0
        self.last_prompt = None
