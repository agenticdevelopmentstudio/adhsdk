from enum import StrEnum


class SupportGrantDecision(StrEnum):
    APPROVED = "approved"
    DENIED = "denied"

    def __str__(self) -> str:
        return str(self.value)
