from enum import StrEnum


class PersonaBootstrapAuthTokenClass(StrEnum):
    PERSONA = "persona"
    VISITOR = "visitor"

    def __str__(self) -> str:
        return str(self.value)
