from enum import StrEnum


class PostV1AccountBodyAppearanceColorMode(StrEnum):
    AUTO = "auto"
    DARK = "dark"
    LIGHT = "light"

    def __str__(self) -> str:
        return str(self.value)
