from enum import StrEnum


class PostV1GamificationConfigBodyMode(StrEnum):
    GAME = "game"
    GAMIFICATION = "gamification"
    NONE = "none"

    def __str__(self) -> str:
        return str(self.value)
