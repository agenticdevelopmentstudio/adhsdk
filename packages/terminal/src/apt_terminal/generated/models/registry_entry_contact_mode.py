from enum import StrEnum


class RegistryEntryContactMode(StrEnum):
    DM = "dm"
    NONE = "none"

    def __str__(self) -> str:
        return str(self.value)
