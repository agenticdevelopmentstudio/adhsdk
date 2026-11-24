from enum import StrEnum


class PostV1AccountBodyAppearanceReduceMotion(StrEnum):
    AUTO = "auto"
    OFF = "off"
    ON = "on"

    def __str__(self) -> str:
        return str(self.value)
