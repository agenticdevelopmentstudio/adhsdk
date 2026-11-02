from enum import StrEnum


class GetRegistryRegistriesRegistryIdEntriesStatus(StrEnum):
    DRAFT = "draft"
    PENDING = "pending"
    PUBLISHED = "published"

    def __str__(self) -> str:
        return str(self.value)
