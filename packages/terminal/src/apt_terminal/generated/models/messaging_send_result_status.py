from enum import StrEnum


class MessagingSendResultStatus(StrEnum):
    FAILED = "failed"
    SENT = "sent"

    def __str__(self) -> str:
        return str(self.value)
