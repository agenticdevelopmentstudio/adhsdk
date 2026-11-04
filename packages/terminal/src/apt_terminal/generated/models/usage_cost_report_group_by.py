from enum import StrEnum


class UsageCostReportGroupBy(StrEnum):
    DAY = "day"
    KEY = "key"

    def __str__(self) -> str:
        return str(self.value)
