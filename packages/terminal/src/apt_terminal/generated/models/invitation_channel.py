from enum import StrEnum


class InvitationChannel(StrEnum):
    EMAIL = "email"
    SMS = "sms"

    def __str__(self) -> str:
        return str(self.value)
