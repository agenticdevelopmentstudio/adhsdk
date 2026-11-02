from enum import StrEnum


class AppearanceSettingsPrefsContrast(StrEnum):
    DEFAULT = "default"
    EXTRA_HIGH = "extra-high"
    HIGH = "high"

    def __str__(self) -> str:
        return str(self.value)
