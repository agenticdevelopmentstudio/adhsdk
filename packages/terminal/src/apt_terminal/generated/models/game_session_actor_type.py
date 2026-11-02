from enum import StrEnum


class GameSessionActorType(StrEnum):
    USER = "user"
    VISITOR = "visitor"

    def __str__(self) -> str:
        return str(self.value)
