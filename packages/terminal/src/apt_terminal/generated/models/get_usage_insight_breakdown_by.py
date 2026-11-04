from enum import StrEnum


class GetUsageInsightBreakdownBy(StrEnum):
    ECOSYSTEM = "ecosystem"
    ORGANIZATION = "organization"
    PERSONA = "persona"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
