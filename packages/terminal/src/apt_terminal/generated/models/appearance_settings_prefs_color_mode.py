from enum import StrEnum


class AppearanceSettingsPrefsColorMode(StrEnum):
    AUTO = "auto"
    DARK = "dark"
    LIGHT = "light"

    def __str__(self) -> str:
        return str(self.value)
