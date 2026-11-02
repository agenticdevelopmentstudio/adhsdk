from enum import StrEnum


class GamificationBoardWindow(StrEnum):
    ALLTIME = "allTime"
    ROLLING30 = "rolling30"
    SEASON = "season"
    TRENDING = "trending"

    def __str__(self) -> str:
        return str(self.value)
