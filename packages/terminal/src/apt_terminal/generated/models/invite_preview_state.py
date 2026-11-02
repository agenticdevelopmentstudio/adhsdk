from enum import StrEnum


class InvitePreviewState(StrEnum):
    ACCEPTED = "accepted"
    EXPIRED = "expired"
    INVALID = "invalid"
    VALID = "valid"

    def __str__(self) -> str:
        return str(self.value)
