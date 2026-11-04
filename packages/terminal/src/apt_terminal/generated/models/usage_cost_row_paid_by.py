from enum import StrEnum


class UsageCostRowPaidBy(StrEnum):
    CUSTOMER_KEY = "customer_key"
    PLATFORM = "platform"

    def __str__(self) -> str:
        return str(self.value)
