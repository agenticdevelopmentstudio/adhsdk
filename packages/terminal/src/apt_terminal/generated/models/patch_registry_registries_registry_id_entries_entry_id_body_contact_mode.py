from enum import StrEnum


class PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyContactMode(StrEnum):
    DM = "dm"
    NONE = "none"

    def __str__(self) -> str:
        return str(self.value)
