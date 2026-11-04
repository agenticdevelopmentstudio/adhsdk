from enum import StrEnum


class GetUsageCostsPaidBy(StrEnum):
    CUSTOMER_KEY = "customer_key"
    PLATFORM = "platform"

    def __str__(self) -> str:
        return str(self.value)
