from enum import StrEnum


class AppearanceSettingsPrefsReduceMotion(StrEnum):
    AUTO = "auto"
    OFF = "off"
    ON = "on"

    def __str__(self) -> str:
        return str(self.value)
