from enum import StrEnum


class PostV1RegistryEntriesByIdBodyContactMode(StrEnum):
    DM = "dm"
    NONE = "none"

    def __str__(self) -> str:
        return str(self.value)
