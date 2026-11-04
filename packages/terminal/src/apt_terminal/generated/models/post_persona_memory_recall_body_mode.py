from enum import StrEnum


class PostPersonaMemoryRecallBodyMode(StrEnum):
    COMBINED = "combined"
    KEYWORD = "keyword"
    SEMANTIC = "semantic"

    def __str__(self) -> str:
        return str(self.value)
