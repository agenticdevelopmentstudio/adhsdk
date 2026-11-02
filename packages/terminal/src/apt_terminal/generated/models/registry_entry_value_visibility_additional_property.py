from enum import StrEnum


class RegistryEntryValueVisibilityAdditionalProperty(StrEnum):
    AUTHENTICATED = "authenticated"
    PRIVATE = "private"
    PUBLIC = "public"

    def __str__(self) -> str:
        return str(self.value)
