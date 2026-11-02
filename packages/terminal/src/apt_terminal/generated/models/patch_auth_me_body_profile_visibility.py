from enum import StrEnum


class PatchAuthMeBodyProfileVisibility(StrEnum):
    HUB = "hub"
    PRIVATE = "private"
    PUBLIC = "public"

    def __str__(self) -> str:
        return str(self.value)
