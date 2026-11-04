from enum import StrEnum


class GetUsageInsightBreakdownSort(StrEnum):
    DIRECT = "direct"
    ESTIMATED = "estimated"
    REQUESTS = "requests"

    def __str__(self) -> str:
        return str(self.value)
