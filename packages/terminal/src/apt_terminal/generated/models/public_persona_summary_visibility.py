from enum import StrEnum


class PublicPersonaSummaryVisibility(StrEnum):
    HUB = "hub"
    PUBLIC = "public"

    def __str__(self) -> str:
        return str(self.value)
