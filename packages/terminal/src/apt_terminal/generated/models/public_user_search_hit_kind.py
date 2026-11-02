from enum import StrEnum


class PublicUserSearchHitKind(StrEnum):
    ORGANIZATION = "organization"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
