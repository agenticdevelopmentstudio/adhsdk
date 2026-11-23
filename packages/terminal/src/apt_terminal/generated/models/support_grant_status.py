from enum import StrEnum


class SupportGrantStatus(StrEnum):
    DENIED = "denied"
    EXPIRED = "expired"
    LAPSED = "lapsed"
    LIVE = "live"
    PENDING = "pending"
    REVOKED = "revoked"

    def __str__(self) -> str:
        return str(self.value)
