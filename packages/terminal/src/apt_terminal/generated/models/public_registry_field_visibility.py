from enum import StrEnum


class PublicRegistryFieldVisibility(StrEnum):
    AUTHENTICATED = "authenticated"
    PUBLIC = "public"

    def __str__(self) -> str:
        return str(self.value)
