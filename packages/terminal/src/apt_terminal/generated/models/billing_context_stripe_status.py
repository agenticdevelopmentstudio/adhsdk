from enum import StrEnum


class BillingContextStripeStatus(StrEnum):
    CONNECTED = "connected"
    NOT_CONNECTED = "not_connected"
    UNKNOWN = "unknown"

    def __str__(self) -> str:
        return str(self.value)
