from enum import StrEnum


class InviteAcceptResultStatus(StrEnum):
    ACCEPTED = "accepted"
    VERIFICATION_REQUIRED = "verification_required"

    def __str__(self) -> str:
        return str(self.value)
