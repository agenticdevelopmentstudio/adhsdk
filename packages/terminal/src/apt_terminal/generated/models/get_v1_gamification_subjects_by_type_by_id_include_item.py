from enum import StrEnum


class GetV1GamificationSubjectsByTypeByIdIncludeItem(StrEnum):
    POINTS = "points"

    def __str__(self) -> str:
        return str(self.value)
