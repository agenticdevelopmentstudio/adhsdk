from enum import StrEnum


class InvitationStatus(StrEnum):
    ACCEPTED = "accepted"
    EXPIRED = "expired"
    REGISTERED = "registered"
    REVOKED = "revoked"
    SENT = "sent"

    def __str__(self) -> str:
        return str(self.value)
