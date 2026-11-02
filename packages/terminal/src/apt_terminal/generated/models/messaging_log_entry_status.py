from enum import StrEnum


class MessagingLogEntryStatus(StrEnum):
    FAILED = "failed"
    SENT = "sent"

    def __str__(self) -> str:
        return str(self.value)
