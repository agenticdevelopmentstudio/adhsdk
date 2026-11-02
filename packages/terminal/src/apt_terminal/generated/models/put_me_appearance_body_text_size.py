from enum import StrEnum


class PutMeAppearanceBodyTextSize(StrEnum):
    DEFAULT = "default"
    EXTRA_LARGE = "extra-large"
    LARGE = "large"
    SMALL = "small"

    def __str__(self) -> str:
        return str(self.value)
