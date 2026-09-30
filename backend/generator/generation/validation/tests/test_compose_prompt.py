"""Tests for the prompt composition layer (compose_prompt.py)."""
import copy
import os
import sys
import unittest

# Ensure generation package is importable
HERE = os.path.dirname(os.path.abspath(__file__))
GEN_DIR = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, GEN_DIR)

from compose_prompt import (
    BlueprintNotFoundError,
    CurriculumNotFoundError,
    InvalidPromptTypeError,
    PromptComposer,
    UnresolvedPlaceholderError,
    compose_prompt,
)


class TestPromptComposer(unittest.TestCase):
    def setUp(self):
        self.composer = PromptComposer()

    def test_bilingual_numeracy(self):
        """Test bilingual numeracy prompt composition."""
        bid = "BP-G1-NUM-032-01"
        res = self.composer.compose(blueprint_id=bid)
        
        self.assertEqual(res.blueprint_id, bid)
        self.assertEqual(res.curriculum_id, "G1-NUM-032")
        self.assertEqual(res.content_id, "GC-G1-NUM-032-01-bi-v1")
        self.assertEqual(res.language_mode, "bilingual")
        self.assertIsNone(res.target_language)
        
        # Verify prompt stack
        expected_stack = ["base_prompt", "numeracy_bilingual", "santali_generation"]
        self.assertEqual(res.prompt_stack, expected_stack)
        
        # Verify versions preserved
        self.assertIn("base_prompt@", res.prompt_version)
        self.assertIn("numeracy_bilingual@", res.prompt_version)
        self.assertIn("santali_generation@", res.prompt_version)
        
        # Verify content text
        text = res.text
        self.assertIn("GC-G1-NUM-032-01-bi-v1", text)
        self.assertIn("BP-G1-NUM-032-01", text)
        self.assertIn("G1-NUM-032", text)
        self.assertIn("# Bilingual numeracy units", text)
        self.assertIn("# Santali (`sat`) rules", text)
        
        # Verify no placeholders remain
        self.assertNotIn("{{", text)
        self.assertNotIn("}}", text)

    def test_bilingual_literacy(self):
        """Test bilingual literacy prompt composition."""
        bid = "BP-G1-LIT-001-01"
        res = self.composer.compose(blueprint_id=bid)
        
        self.assertEqual(res.blueprint_id, bid)
        self.assertEqual(res.curriculum_id, "G1-LIT-001")
        self.assertEqual(res.content_id, "GC-G1-LIT-001-01-bi-v1")
        self.assertEqual(res.language_mode, "bilingual")
        
        expected_stack = ["base_prompt", "literacy_bilingual", "santali_generation"]
        self.assertEqual(res.prompt_stack, expected_stack)
        
        text = res.text
        self.assertIn("GC-G1-LIT-001-01-bi-v1", text)
        self.assertIn("# Bilingual literacy units", text)
        self.assertIn("# Santali (`sat`) rules", text)
        self.assertNotIn("{{", text)

    def test_parallel_literacy_hindi(self):
        """Test parallel monolingual literacy prompt for Hindi."""
        bid = "BP-G1-LIT-015-01"
        res = self.composer.compose(blueprint_id=bid, target_language="hi")
        
        self.assertEqual(res.blueprint_id, bid)
        self.assertEqual(res.content_id, "GC-G1-LIT-015-01-hi-v1")
        self.assertEqual(res.language_mode, "parallel_monolingual")
        self.assertEqual(res.target_language, "hi")
        
        # Santali prompt should NOT be included for Hindi
        expected_stack = ["base_prompt", "literacy_parallel"]
        self.assertEqual(res.prompt_stack, expected_stack)
        self.assertNotIn("santali_generation", res.prompt_stack)
        
        text = res.text
        self.assertIn("Target language for this call: `hi`", text)
        self.assertIn('`languages` = `["hi"]`', text)
        self.assertIn("`content_id` ends in `-hi-v1`", text)
        self.assertNotIn("# Santali (`sat`) rules", text)
        self.assertNotIn("{{", text)

    def test_parallel_literacy_santali(self):
        """Test parallel monolingual literacy prompt for Santali."""
        bid = "BP-G1-LIT-015-01"
        res = self.composer.compose(blueprint_id=bid, target_language="sat")
        
        self.assertEqual(res.blueprint_id, bid)
        self.assertEqual(res.content_id, "GC-G1-LIT-015-01-sat-v1")
        self.assertEqual(res.language_mode, "parallel_monolingual")
        self.assertEqual(res.target_language, "sat")
        
        # Santali prompt MUST be included for Santali parallel
        expected_stack = ["base_prompt", "literacy_parallel", "santali_generation"]
        self.assertEqual(res.prompt_stack, expected_stack)
        
        text = res.text
        self.assertIn("Target language for this call: `sat`", text)
        self.assertIn('`languages` = `["sat"]`', text)
        self.assertIn("`content_id` ends in `-sat-v1`", text)
        self.assertIn("# Santali (`sat`) rules", text)
        self.assertNotIn("{{", text)

    def test_parallel_missing_target_language(self):
        """Test that parallel monolingual requires target_language."""
        bid = "BP-G1-LIT-015-01"
        with self.assertRaises(ValueError) as ctx:
            self.composer.compose(blueprint_id=bid)
        self.assertIn("target_language", str(ctx.exception))

    def test_parallel_invalid_target_language(self):
        """Test that target_language must be in blueprint's language_pair."""
        bid = "BP-G1-LIT-015-01"
        with self.assertRaises(ValueError) as ctx:
            self.composer.compose(blueprint_id=bid, target_language="en")
        self.assertIn("not in blueprint language_pair", str(ctx.exception))

    def test_santali_prompt_inclusion_rules(self):
        """Verify exact rules for santali_generation.md inclusion."""
        # 1. Bilingual numeracy -> Included
        res_num = self.composer.compose("BP-G1-NUM-002-01")
        self.assertIn("santali_generation", res_num.prompt_stack)

        # 2. Bilingual literacy -> Included
        res_lit_bi = self.composer.compose("BP-G1-LIT-006-01")
        self.assertIn("santali_generation", res_lit_bi.prompt_stack)

        # 3. Parallel literacy (hi) -> NOT included
        res_lit_hi = self.composer.compose("BP-G1-LIT-011-01", target_language="hi")
        self.assertNotIn("santali_generation", res_lit_hi.prompt_stack)

        # 4. Parallel literacy (sat) -> Included
        res_lit_sat = self.composer.compose("BP-G1-LIT-011-01", target_language="sat")
        self.assertIn("santali_generation", res_lit_sat.prompt_stack)

    def test_unresolved_placeholder_failure(self):
        """Test that composition fails if an unresolved placeholder remains."""
        bid = "BP-G1-NUM-032-01"
        # Temporarily mock get_prompt_text_and_version to inject an unknown placeholder
        original_get = self.composer.get_prompt_text_and_version

        def mock_get(name):
            txt, ver = original_get(name)
            if name == "numeracy_bilingual":
                txt += "\n\nTest with {{UNKNOWN_VARIABLE}} placeholder."
            return txt, ver

        self.composer.get_prompt_text_and_version = mock_get
        try:
            with self.assertRaises(UnresolvedPlaceholderError) as ctx:
                self.composer.compose(blueprint_id=bid)
            self.assertIn("UNKNOWN_VARIABLE", str(ctx.exception))
        finally:
            self.composer.get_prompt_text_and_version = original_get

    def test_invalid_blueprint_id(self):
        """Test that non-existent blueprint ID raises BlueprintNotFoundError."""
        with self.assertRaises(BlueprintNotFoundError) as ctx:
            self.composer.compose(blueprint_id="BP-NONEXISTENT-999")
        self.assertIn("BP-NONEXISTENT-999", str(ctx.exception))

    def test_invalid_prompt_type(self):
        """Test that an invalid or unsupported domain/mode raises InvalidPromptTypeError."""
        # Mock a blueprint with an invalid domain
        self.composer._cache["blueprints"] = {
            "BP-TEST-INVALID": {
                "blueprint_id": "BP-TEST-INVALID",
                "curriculum_id": "G1-NUM-032",
                "domain": "science",
                "language_mode": "bilingual",
                "language_pair": ["hi", "sat"],
            }
        }
        with self.assertRaises(InvalidPromptTypeError) as ctx:
            self.composer.compose("BP-TEST-INVALID")
        self.assertIn("Unsupported domain: 'science'", str(ctx.exception))

    def test_determinism(self):
        """Verify that identical inputs produce identical composed prompt text."""
        p1 = compose_prompt("BP-G1-NUM-032-01")
        p2 = compose_prompt("BP-G1-NUM-032-01")
        self.assertEqual(p1.text, p2.text)
        self.assertEqual(p1.content_id, p2.content_id)
        self.assertEqual(p1.prompt_version, p2.prompt_version)

    def test_all_35_blueprints_compose(self):
        """Verify that all 35 blueprints in the project can be composed without error."""
        blueprints = self.composer.blueprints
        self.assertEqual(len(blueprints), 35)

        for bid, bp in blueprints.items():
            if bp["language_mode"] == "bilingual":
                res = self.composer.compose(bid)
                self.assertTrue(res.text)
                self.assertNotIn("{{", res.text)
            else:
                for lang in bp["language_pair"]:
                    res = self.composer.compose(bid, target_language=lang)
                    self.assertTrue(res.text)
                    self.assertNotIn("{{", res.text)


if __name__ == "__main__":
    unittest.main()
