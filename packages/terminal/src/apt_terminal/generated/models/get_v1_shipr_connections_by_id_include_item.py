from enum import StrEnum


class GetV1ShiprConnectionsByIdIncludeItem(StrEnum):
    DECLARATION = "declaration"

    def __str__(self) -> str:
        return str(self.value)
