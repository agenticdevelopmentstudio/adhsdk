from enum import StrEnum


class PostV1MemoriesRecallBodyScope(StrEnum):
    GLOBAL = "global"

    def __str__(self) -> str:
        return str(self.value)
