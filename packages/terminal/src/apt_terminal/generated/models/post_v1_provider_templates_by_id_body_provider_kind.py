from enum import StrEnum


class PostV1ProviderTemplatesByIdBodyProviderKind(StrEnum):
    ANTHROPIC = "anthropic"
    EXTERNAL = "external"
    GEMINI = "gemini"
    OPENAI = "openai"

    def __str__(self) -> str:
        return str(self.value)
