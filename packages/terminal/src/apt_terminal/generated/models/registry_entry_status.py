from enum import StrEnum


class RegistryEntryStatus(StrEnum):
    DRAFT = "draft"
    PENDING = "pending"
    PUBLISHED = "published"

    def __str__(self) -> str:
        return str(self.value)
