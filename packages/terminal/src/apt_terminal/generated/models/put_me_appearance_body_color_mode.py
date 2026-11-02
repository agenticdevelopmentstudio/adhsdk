from enum import StrEnum


class PutMeAppearanceBodyColorMode(StrEnum):
    AUTO = "auto"
    DARK = "dark"
    LIGHT = "light"

    def __str__(self) -> str:
        return str(self.value)
