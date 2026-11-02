from enum import StrEnum


class GamificationRealmBadgeTierType1(StrEnum):
    BRONZE = "bronze"
    GOLD = "gold"
    NONE = "none"
    PLATINUM = "platinum"
    SILVER = "silver"

    def __str__(self) -> str:
        return str(self.value)
