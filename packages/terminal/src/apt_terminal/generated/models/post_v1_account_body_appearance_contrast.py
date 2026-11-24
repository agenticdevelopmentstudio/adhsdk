from enum import StrEnum


class PostV1AccountBodyAppearanceContrast(StrEnum):
    DEFAULT = "default"
    EXTRA_HIGH = "extra-high"
    HIGH = "high"

    def __str__(self) -> str:
        return str(self.value)
