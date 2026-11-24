from enum import StrEnum


class PostV1PersonasPreviewBodyHistoryItemRole(StrEnum):
    ASSISTANT = "assistant"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
