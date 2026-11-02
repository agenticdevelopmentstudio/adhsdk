from enum import StrEnum


class GameSessionStatus(StrEnum):
    ABANDONED = "abandoned"
    ACTIVE = "active"
    ENDED = "ended"

    def __str__(self) -> str:
        return str(self.value)
