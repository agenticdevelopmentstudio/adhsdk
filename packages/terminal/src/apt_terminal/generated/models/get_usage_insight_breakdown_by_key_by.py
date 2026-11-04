from enum import StrEnum


class GetUsageInsightBreakdownByKeyBy(StrEnum):
    ECOSYSTEM = "ecosystem"
    ORGANIZATION = "organization"
    PERSONA = "persona"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
