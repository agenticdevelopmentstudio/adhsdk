from enum import StrEnum


class PublicRegistryEntryDetailContactMode(StrEnum):
    DM = "dm"
    NONE = "none"

    def __str__(self) -> str:
        return str(self.value)
