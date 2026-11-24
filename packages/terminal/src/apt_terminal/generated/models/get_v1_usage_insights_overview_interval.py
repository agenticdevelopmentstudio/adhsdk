from enum import StrEnum


class GetV1UsageInsightsOverviewInterval(StrEnum):
    DAY = "day"
    MONTH = "month"
    WEEK = "week"

    def __str__(self) -> str:
        return str(self.value)
