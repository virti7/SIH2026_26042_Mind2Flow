"""Unit and integration tests for GenerationOrchestrator."""
import json
import os
import shutil
import sys
import tempfile
import unittest

# Ensure generation package and validators are in sys.path
HERE = os.path.dirname(os.path.abspath(__file__))
GEN_DIR = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, GEN_DIR)
sys.path.insert(0, os.path.join(GEN_DIR, "validation"))

from orchestrator import GenerationOrchestrator, GenerationResult, main
from providers.base import LLMProvider
from providers.mock import MockProvider
from unittest.mock import patch, MagicMock


class FailingProvider(LLMProvider):
    """Test provider that always raises an unhandled runtime error."""
    def generate(self, prompt: str) -> str:
        raise RuntimeError("Simulated upstream provider outage / network timeout")


class TestGenerationOrchestrator(unittest.TestCase):
    def setUp(self):
        # Create an isolated temporary directory for test output artifacts
        self.test_dir = tempfile.mkdtemp(prefix="test_orch_")

    def tearDown(self):
        # Clean up temporary test artifacts
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_successful_generation(self):
        """Test happy path with MockProvider in 'valid' mode."""
        provider = MockProvider(mode="valid")
        orchestrator = GenerationOrchestrator(provider=provider, output_dir=self.test_dir)
        
        bid = "BP-G1-NUM-032-01"
        res = orchestrator.generate(blueprint_id=bid)
        
        # Verify result structure
        self.assertTrue(res.is_success)
        self.assertEqual(res.status, "success")
        self.assertEqual(res.blueprint_id, bid)
        self.assertEqual(res.content_id, "GC-G1-NUM-032-01-bi-v1")
        self.assertEqual(res.provider_used, "MockProvider")
        self.assertEqual(res.validation_status, "PASSED")
        self.assertEqual(len(res.errors), 0)
        
        # Verify provider call metrics
        self.assertEqual(provider.call_count, 1)
        self.assertIsNotNone(provider.last_prompt)
        self.assertIn(bid, provider.last_prompt)
        self.assertNotIn("{{", provider.last_prompt)
        
        # Verify output artifact
        self.assertIsNotNone(res.output_path)
        self.assertTrue(os.path.exists(res.output_path))
        with open(res.output_path, "r", encoding="utf-8") as f:
            written_data = json.load(f)
        self.assertEqual(written_data["content_id"], res.content_id)
        self.assertEqual(written_data["blueprint_id"], bid)

    def test_invalid_json(self):
        """Test rejection of malformed JSON from provider."""
        provider = MockProvider(mode="invalid_json")
        orchestrator = GenerationOrchestrator(provider=provider, output_dir=self.test_dir)
        
        bid = "BP-G1-NUM-032-01"
        res = orchestrator.generate(blueprint_id=bid)
        
        self.assertFalse(res.is_success)
        self.assertEqual(res.status, "json_error")
        self.assertEqual(provider.call_count, 1)
        self.assertGreater(len(res.errors), 0)
        self.assertIn("Failed to parse model response as JSON", res.errors[0])
        
        # Verify no output file was created
        expected_file = os.path.join(self.test_dir, "GC-G1-NUM-032-01-bi-v1.json")
        self.assertFalse(os.path.exists(expected_file))

    def test_schema_invalid(self):
        """Test rejection of schema-invalid JSON."""
        provider = MockProvider(mode="schema_invalid")
        orchestrator = GenerationOrchestrator(provider=provider, output_dir=self.test_dir)
        
        bid = "BP-G1-NUM-032-01"
        res = orchestrator.generate(blueprint_id=bid)
        
        self.assertFalse(res.is_success)
        self.assertEqual(res.status, "schema_error")
        self.assertEqual(res.validation_status, "FAILED")
        self.assertGreater(len(res.errors), 0)
        
        # Verify error mentions the missing schema property
        self.assertTrue(any("'answer_key' is a required property" in err for err in res.errors))
        
        # Verify no output file was created
        expected_file = os.path.join(self.test_dir, "GC-G1-NUM-032-01-bi-v1.json")
        self.assertFalse(os.path.exists(expected_file))

    def test_content_invalid(self):
        """Test rejection of schema-valid but content-invalid JSON (NUM_MAX_SUM)."""
        provider = MockProvider(mode="content_invalid")
        orchestrator = GenerationOrchestrator(provider=provider, output_dir=self.test_dir)
        
        bid = "BP-G1-NUM-032-01"
        res = orchestrator.generate(blueprint_id=bid)
        
        self.assertFalse(res.is_success)
        self.assertEqual(res.status, "content_validation_error")
        self.assertEqual(res.validation_status, "FAILED")
        self.assertGreater(len(res.errors), 0)
        
        # Content error NUM_MAX_SUM must be present
        error_codes = [e["code"] if isinstance(e, dict) else e for e in res.errors]
        self.assertIn("NUM_MAX_SUM", error_codes)
        
        # Verify no output file was created
        expected_file = os.path.join(self.test_dir, "GC-G1-NUM-032-01-bi-v1.json")
        self.assertFalse(os.path.exists(expected_file))

    def test_provider_failure(self):
        """Test graceful error handling when provider raises an exception."""
        provider = FailingProvider()
        orchestrator = GenerationOrchestrator(provider=provider, output_dir=self.test_dir)
        
        bid = "BP-G1-NUM-032-01"
        res = orchestrator.generate(blueprint_id=bid)
        
        self.assertFalse(res.is_success)
        self.assertEqual(res.status, "provider_error")
        self.assertGreater(len(res.errors), 0)
        self.assertIn("Simulated upstream provider outage", res.errors[0])
        
        # Verify no output file was created
        expected_file = os.path.join(self.test_dir, "GC-G1-NUM-032-01-bi-v1.json")
        self.assertFalse(os.path.exists(expected_file))

    def test_atomicity_and_file_protection(self):
        """Test atomic writes and overwrite protection."""
        content_id = "GC-G1-NUM-032-01-bi-v1"
        target_path = os.path.join(self.test_dir, f"{content_id}.json")
        
        # Pre-create an existing file with sentinel content
        sentinel_content = {"sentinel": "pre-existing valid data"}
        with open(target_path, "w", encoding="utf-8") as f:
            json.dump(sentinel_content, f)
            
        # 1. Attempt generation without force=True -> must fail with file_exists_error
        provider = MockProvider(mode="valid")
        orchestrator = GenerationOrchestrator(provider=provider, output_dir=self.test_dir)
        res = orchestrator.generate(blueprint_id="BP-G1-NUM-032-01", force=False)
        
        self.assertEqual(res.status, "file_exists_error")
        self.assertEqual(provider.call_count, 0)  # Should not call provider if file exists and force=False
        
        # Verify sentinel content was not touched
        with open(target_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        self.assertEqual(data, sentinel_content)

        # 2. Attempt generation with force=True, but provider fails content validation
        provider_invalid = MockProvider(mode="content_invalid")
        orchestrator_invalid = GenerationOrchestrator(provider=provider_invalid, output_dir=self.test_dir)
        res_fail = orchestrator_invalid.generate(blueprint_id="BP-G1-NUM-032-01", force=True)
        
        self.assertEqual(res_fail.status, "content_validation_error")
        # Sentinel content must STILL be intact (atomic failure)
        with open(target_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        self.assertEqual(data, sentinel_content)

        # 3. Generation with force=True and valid provider -> succeeds and replaces target
        res_force = orchestrator.generate(blueprint_id="BP-G1-NUM-032-01", force=True)
        self.assertTrue(res_force.is_success)
        with open(target_path, "r", encoding="utf-8") as f:
            new_data = json.load(f)
        self.assertEqual(new_data["content_id"], content_id)
        self.assertNotIn("sentinel", new_data)

    def test_determinism(self):
        """Test that running the same blueprint with the same mock fixture produces identical output."""
        dir1 = os.path.join(self.test_dir, "run1")
        dir2 = os.path.join(self.test_dir, "run2")
        
        p1 = MockProvider(mode="valid")
        p2 = MockProvider(mode="valid")
        
        orch1 = GenerationOrchestrator(provider=p1, output_dir=dir1)
        orch2 = GenerationOrchestrator(provider=p2, output_dir=dir2)
        
        res1 = orch1.generate("BP-G1-NUM-032-01")
        res2 = orch2.generate("BP-G1-NUM-032-01")
        
        self.assertTrue(res1.is_success)
        self.assertTrue(res2.is_success)
        
        with open(res1.output_path, "r", encoding="utf-8") as f1, open(res2.output_path, "r", encoding="utf-8") as f2:
            self.assertEqual(f1.read(), f2.read())

    def test_prompt_verification(self):
        """Verify the exact prompt received by the provider matches composer expectations."""
        provider = MockProvider(mode="valid")
        orchestrator = GenerationOrchestrator(provider=provider, output_dir=self.test_dir)
        
        bid = "BP-G1-NUM-032-01"
        orchestrator.generate(blueprint_id=bid)
        
        self.assertEqual(provider.call_count, 1)
        prompt = provider.last_prompt
        self.assertIsNotNone(prompt)
        
        # Must contain authoritative blueprint and curriculum IDs
        self.assertIn("BP-G1-NUM-032-01", prompt)
        self.assertIn("G1-NUM-032", prompt)
        self.assertIn("GC-G1-NUM-032-01-bi-v1", prompt)
        
        # Must contain prompt instructions
        self.assertIn("# Non-negotiable rules", prompt)
        self.assertIn("# Bilingual numeracy units", prompt)
        self.assertIn("# Santali (`sat`) rules", prompt)
        
        # Must NOT contain unresolved placeholders
        self.assertNotIn("{{CONTENT_ID}}", prompt)
        self.assertNotIn("{{BLUEPRINT_RECORD}}", prompt)
        self.assertNotIn("{{CURRICULUM_RECORD}}", prompt)
        self.assertNotIn("{{PROTOTYPE_POLICY}}", prompt)
        self.assertNotIn("{{GENERATED_CONTENT_SCHEMA}}", prompt)
        self.assertNotIn("{{", prompt)

    def test_cli_provider_mock(self):
        """Verify CLI accepts --provider mock and generates output."""
        test_args = [
            "orchestrator.py",
            "--blueprint-id", "BP-G1-NUM-032-01",
            "--provider", "mock",
            "--output-dir", self.test_dir,
            "--json",
        ]
        with patch("sys.argv", test_args):
            with patch("sys.stdout"):
                with self.assertRaises(SystemExit) as ctx:
                    main()
                self.assertEqual(ctx.exception.code, 0)
        expected_file = os.path.join(self.test_dir, "GC-G1-NUM-032-01-bi-v1.json")
        self.assertTrue(os.path.exists(expected_file))

    def test_cli_rejects_removed_cloud_provider(self):
        """The cloud providers were removed with the external AI stack.

        Passing one must be rejected by argparse rather than silently falling
        back to a different provider.
        """
        test_args = [
            "orchestrator.py",
            "--blueprint-id", "BP-G1-NUM-032-01",
            "--provider", "gemini",
        ]
        with patch("sys.argv", test_args):
            with patch("sys.stderr"):
                with self.assertRaises(SystemExit) as ctx:
                    main()
        self.assertEqual(ctx.exception.code, 2)


if __name__ == "__main__":
    unittest.main()

