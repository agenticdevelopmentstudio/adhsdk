from enum import StrEnum


class PersonaMemorySource(StrEnum):
    INFERRED = "inferred"
    TOOL = "tool"
    USER_STATED = "user_stated"

    def __str__(self) -> str:
        return str(self.value)
