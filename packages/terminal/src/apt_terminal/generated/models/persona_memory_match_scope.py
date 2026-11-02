from enum import StrEnum


class PersonaMemoryMatchScope(StrEnum):
    PERSONA = "persona"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
