from enum import StrEnum


class GetV1UsageCostsGroupBy(StrEnum):
    DAY = "day"
    KEY = "key"

    def __str__(self) -> str:
        return str(self.value)
