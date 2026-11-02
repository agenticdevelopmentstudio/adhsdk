from enum import StrEnum


class PersonaSheetSubjectType(StrEnum):
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
