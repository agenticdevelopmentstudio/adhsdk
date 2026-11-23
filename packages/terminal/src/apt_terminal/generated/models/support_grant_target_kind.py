from enum import StrEnum


class SupportGrantTargetKind(StrEnum):
    ACCOUNT = "account"
    CUSTOMER = "customer"

    def __str__(self) -> str:
        return str(self.value)
