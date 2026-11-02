from enum import StrEnum


class GameInstanceLocationType(StrEnum):
    GAME = "game"
    INSTANCE = "instance"
    PLAYER = "player"
    SESSION = "session"

    def __str__(self) -> str:
        return str(self.value)
