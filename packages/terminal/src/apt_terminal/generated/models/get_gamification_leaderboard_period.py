from enum import StrEnum


class GetGamificationLeaderboardPeriod(StrEnum):
    ALL = "all"
    MONTH = "month"
    WEEK = "week"

    def __str__(self) -> str:
        return str(self.value)
