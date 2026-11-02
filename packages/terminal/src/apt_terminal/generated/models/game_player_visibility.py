from enum import StrEnum


class GamePlayerVisibility(StrEnum):
    PRIVATE = "private"
    PUBLIC = "public"
    UNLISTED = "unlisted"

    def __str__(self) -> str:
        return str(self.value)
