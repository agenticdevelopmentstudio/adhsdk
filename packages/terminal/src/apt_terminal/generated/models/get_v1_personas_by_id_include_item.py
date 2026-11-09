from enum import StrEnum


class GetV1PersonasByIdIncludeItem(StrEnum):
    RECAP = "recap"
    SHEET = "sheet"

    def __str__(self) -> str:
        return str(self.value)
