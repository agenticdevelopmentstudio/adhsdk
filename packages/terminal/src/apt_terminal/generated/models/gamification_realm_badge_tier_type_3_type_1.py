from enum import StrEnum


class GamificationRealmBadgeTierType3Type1(StrEnum):
    BRONZE = "bronze"
    GOLD = "gold"
    NONE = "none"
    PLATINUM = "platinum"
    SILVER = "silver"

    def __str__(self) -> str:
        return str(self.value)
