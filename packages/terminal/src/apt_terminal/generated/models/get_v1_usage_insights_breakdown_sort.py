from enum import StrEnum


class GetV1UsageInsightsBreakdownSort(StrEnum):
    DIRECT = "direct"
    ESTIMATED = "estimated"
    REQUESTS = "requests"

    def __str__(self) -> str:
        return str(self.value)
