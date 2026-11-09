from enum import StrEnum


class PostV1RegistriesByIdBodyVisibility(StrEnum):
    HUB = "hub"
    PRIVATE = "private"
    PUBLIC = "public"

    def __str__(self) -> str:
        return str(self.value)
