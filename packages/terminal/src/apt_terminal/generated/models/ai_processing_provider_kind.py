from enum import StrEnum


class AiProcessingProviderKind(StrEnum):
    ANTHROPIC = "anthropic"
    GEMINI = "gemini"
    LOCAL = "local"
    OPENAI = "openai"

    def __str__(self) -> str:
        return str(self.value)
