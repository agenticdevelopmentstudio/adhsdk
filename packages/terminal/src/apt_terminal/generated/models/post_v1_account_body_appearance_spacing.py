from enum import StrEnum


class PostV1AccountBodyAppearanceSpacing(StrEnum):
    COMFORTABLE = "comfortable"
    COMPACT = "compact"
    SPACIOUS = "spacious"

    def __str__(self) -> str:
        return str(self.value)
