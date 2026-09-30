"""Abstract base class for LLM providers."""
from abc import ABC, abstractmethod


class LLMProvider(ABC):
    """Abstract interface for LLM providers in the bilingual FLN generation pipeline.
    
    Any concrete provider (MockProvider, etc.)
    must implement the generate method, taking a composed prompt string and
    returning the raw string response from the model.
    """

    @abstractmethod
    def generate(self, prompt: str) -> str:
        """Send a prompt to the LLM and return the raw text response.

        Args:
            prompt: The fully composed prompt string.

        Returns:
            The raw string response returned by the model.

        Raises:
            Exception: Concrete implementations should raise informative errors
                       on network, authentication, or provider-level failures.
        """
        pass
