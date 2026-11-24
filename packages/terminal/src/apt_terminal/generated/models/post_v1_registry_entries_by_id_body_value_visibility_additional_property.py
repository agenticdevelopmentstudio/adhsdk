from enum import StrEnum


class PostV1RegistryEntriesByIdBodyValueVisibilityAdditionalProperty(StrEnum):
    AUTHENTICATED = "authenticated"
    PRIVATE = "private"
    PUBLIC = "public"

    def __str__(self) -> str:
        return str(self.value)
