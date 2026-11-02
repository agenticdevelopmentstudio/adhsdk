from enum import StrEnum


class GameArtifactVisibility(StrEnum):
    PRIVATE = "private"
    PUBLIC = "public"
    UNLISTED = "unlisted"

    def __str__(self) -> str:
        return str(self.value)
