from enum import StrEnum


class GetV1UsersByIdIncludeItem(StrEnum):
    SHEET = "sheet"

    def __str__(self) -> str:
        return str(self.value)
