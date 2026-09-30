"""Content-generation provider abstraction.

Only the offline ``MockProvider`` remains. The cloud providers were removed
along with the rest of the external AI stack, so this package can no longer
generate content from a remote model.
"""
from .base import LLMProvider
from .mock import MockProvider

__all__ = ["LLMProvider", "MockProvider"]
