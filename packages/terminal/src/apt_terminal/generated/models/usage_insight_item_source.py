from enum import StrEnum


class UsageInsightItemSource(StrEnum):
    CAPTURED = "captured"
    CUSTOMER_KEY = "customer_key"
    MIXED = "mixed"
    RATE = "rate"
    UNPRICED = "unpriced"

    def __str__(self) -> str:
        return str(self.value)
