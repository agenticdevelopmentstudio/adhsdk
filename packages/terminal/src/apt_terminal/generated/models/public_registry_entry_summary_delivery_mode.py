from enum import StrEnum


class PublicRegistryEntrySummaryDeliveryMode(StrEnum):
    HYBRID = "hybrid"
    IN_PERSON = "in_person"
    VIRTUAL = "virtual"

    def __str__(self) -> str:
        return str(self.value)
