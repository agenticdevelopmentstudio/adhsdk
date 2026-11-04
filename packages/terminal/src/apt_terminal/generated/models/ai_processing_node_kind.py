from enum import StrEnum


class AiProcessingNodeKind(StrEnum):
    SWIFT = "swift"
    TYPESCRIPT = "typescript"

    def __str__(self) -> str:
        return str(self.value)
