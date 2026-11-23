from enum import StrEnum


class SupportBreakGlassRequestTargetKind(StrEnum):
    ACCOUNT = "account"
    CUSTOMER = "customer"

    def __str__(self) -> str:
        return str(self.value)
