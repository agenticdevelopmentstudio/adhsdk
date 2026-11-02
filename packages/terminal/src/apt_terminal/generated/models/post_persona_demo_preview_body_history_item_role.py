from enum import StrEnum


class PostPersonaDemoPreviewBodyHistoryItemRole(StrEnum):
    ASSISTANT = "assistant"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
