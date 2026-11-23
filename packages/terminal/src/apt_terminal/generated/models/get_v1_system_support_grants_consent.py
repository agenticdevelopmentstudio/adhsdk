from enum import StrEnum


class GetV1SystemSupportGrantsConsent(StrEnum):
    BREAK_GLASS = "break_glass"
    CUSTOMER = "customer"

    def __str__(self) -> str:
        return str(self.value)
