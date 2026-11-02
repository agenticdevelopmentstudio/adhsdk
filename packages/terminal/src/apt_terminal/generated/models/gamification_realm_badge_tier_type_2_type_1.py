from enum import StrEnum


class GamificationRealmBadgeTierType2Type1(StrEnum):
    BRONZE = "bronze"
    GOLD = "gold"
    NONE = "none"
    PLATINUM = "platinum"
    SILVER = "silver"

    def __str__(self) -> str:
        return str(self.value)
