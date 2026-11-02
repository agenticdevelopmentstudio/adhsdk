from enum import StrEnum


class PublicRegistryEntryDetailProviderType(StrEnum):
    ORGANIZATION = "organization"
    PERSON = "person"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
