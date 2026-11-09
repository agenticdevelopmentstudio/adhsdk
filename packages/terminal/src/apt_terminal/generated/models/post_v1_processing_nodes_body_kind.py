from enum import StrEnum


class PostV1ProcessingNodesBodyKind(StrEnum):
    SWIFT = "swift"
    TYPESCRIPT = "typescript"

    def __str__(self) -> str:
        return str(self.value)
