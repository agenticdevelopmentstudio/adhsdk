from enum import StrEnum


class PostV1PersonasByIdActorsBodyKind(StrEnum):
    ORG = "org"
    TEAM = "team"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
