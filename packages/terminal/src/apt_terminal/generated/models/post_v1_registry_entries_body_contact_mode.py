from enum import StrEnum


class PostV1RegistryEntriesBodyContactMode(StrEnum):
    DM = "dm"
    NONE = "none"

    def __str__(self) -> str:
        return str(self.value)
