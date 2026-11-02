from enum import StrEnum


class GamificationRealmConfigMode(StrEnum):
    GAME = "game"
    GAMIFICATION = "gamification"
    NONE = "none"

    def __str__(self) -> str:
        return str(self.value)
