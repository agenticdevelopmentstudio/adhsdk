from enum import StrEnum


class PutMeAppearanceBodyContrast(StrEnum):
    DEFAULT = "default"
    EXTRA_HIGH = "extra-high"
    HIGH = "high"

    def __str__(self) -> str:
        return str(self.value)
