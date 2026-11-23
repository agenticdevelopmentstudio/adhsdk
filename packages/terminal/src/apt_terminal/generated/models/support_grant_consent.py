from enum import StrEnum


class SupportGrantConsent(StrEnum):
    BREAK_GLASS = "break_glass"
    CUSTOMER = "customer"

    def __str__(self) -> str:
        return str(self.value)
