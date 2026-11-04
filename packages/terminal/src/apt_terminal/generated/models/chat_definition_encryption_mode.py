from enum import StrEnum


class ChatDefinitionEncryptionMode(StrEnum):
    NONE = "none"

    def __str__(self) -> str:
        return str(self.value)
