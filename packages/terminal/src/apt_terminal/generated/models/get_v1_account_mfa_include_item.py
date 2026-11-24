from enum import StrEnum


class GetV1AccountMfaIncludeItem(StrEnum):
    PREFERENCE = "preference"

    def __str__(self) -> str:
        return str(self.value)
