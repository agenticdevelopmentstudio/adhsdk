from enum import StrEnum


class GamificationLeagueStatKey(StrEnum):
    ADVENTURES = "adventures"
    ALLIES = "allies"
    DAYS_ACTIVE = "days_active"

    def __str__(self) -> str:
        return str(self.value)
