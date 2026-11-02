from enum import StrEnum


class PutPersonaProviderTemplatesIdBodyProviderKind(StrEnum):
    ANTHROPIC = "anthropic"
    EXTERNAL = "external"
    GEMINI = "gemini"
    OPENAI = "openai"

    def __str__(self) -> str:
        return str(self.value)
