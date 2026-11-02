from enum import StrEnum


class GameDefinitionStatus(StrEnum):
    ACTIVE = "active"
    RETIRED = "retired"

    def __str__(self) -> str:
        return str(self.value)
