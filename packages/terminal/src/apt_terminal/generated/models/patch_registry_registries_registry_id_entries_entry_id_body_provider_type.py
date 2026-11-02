from enum import StrEnum


class PatchRegistryRegistriesRegistryIdEntriesEntryIdBodyProviderType(StrEnum):
    ORGANIZATION = "organization"
    PERSON = "person"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
