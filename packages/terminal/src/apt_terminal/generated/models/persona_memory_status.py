from enum import StrEnum


class PersonaMemoryStatus(StrEnum):
    ACTIVE = "active"
    ARCHIVED = "archived"
    SUPERSEDED = "superseded"

    def __str__(self) -> str:
        return str(self.value)
