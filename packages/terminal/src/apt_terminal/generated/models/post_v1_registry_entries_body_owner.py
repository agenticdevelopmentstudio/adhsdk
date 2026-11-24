from enum import StrEnum


class PostV1RegistryEntriesBodyOwner(StrEnum):
    ME = "me"

    def __str__(self) -> str:
        return str(self.value)
