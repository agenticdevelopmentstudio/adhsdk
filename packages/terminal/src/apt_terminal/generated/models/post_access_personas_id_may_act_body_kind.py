from enum import StrEnum


class PostAccessPersonasIdMayActBodyKind(StrEnum):
    ORG = "org"
    TEAM = "team"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
