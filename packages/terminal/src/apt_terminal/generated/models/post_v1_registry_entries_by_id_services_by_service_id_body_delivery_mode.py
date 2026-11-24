from enum import StrEnum


class PostV1RegistryEntriesByIdServicesByServiceIdBodyDeliveryMode(StrEnum):
    HYBRID = "hybrid"
    IN_PERSON = "in_person"
    VIRTUAL = "virtual"

    def __str__(self) -> str:
        return str(self.value)
