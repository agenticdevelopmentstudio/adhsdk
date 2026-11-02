from enum import StrEnum


class PostRegistryRegistriesRegistryIdEntriesBodyContactMode(StrEnum):
    DM = "dm"
    NONE = "none"

    def __str__(self) -> str:
        return str(self.value)
