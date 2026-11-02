from enum import StrEnum


class GamePublicProfileVisibility(StrEnum):
    PUBLIC = "public"
    UNLISTED = "unlisted"

    def __str__(self) -> str:
        return str(self.value)
