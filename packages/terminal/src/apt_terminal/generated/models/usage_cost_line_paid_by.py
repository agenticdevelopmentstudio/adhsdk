from enum import StrEnum


class UsageCostLinePaidBy(StrEnum):
    CUSTOMER_KEY = "customer_key"
    PLATFORM = "platform"

    def __str__(self) -> str:
        return str(self.value)
