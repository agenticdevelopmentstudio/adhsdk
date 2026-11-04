from enum import StrEnum


class GetUsageCostsGroupBy(StrEnum):
    DAY = "day"
    KEY = "key"

    def __str__(self) -> str:
        return str(self.value)
