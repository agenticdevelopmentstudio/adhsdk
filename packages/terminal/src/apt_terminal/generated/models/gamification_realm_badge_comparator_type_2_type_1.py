from enum import StrEnum


class GamificationRealmBadgeComparatorType2Type1(StrEnum):
    VALUE_0 = ">="
    VALUE_1 = ">"
    VALUE_2 = "="

    def __str__(self) -> str:
        return str(self.value)
