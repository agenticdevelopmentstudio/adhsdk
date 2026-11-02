from enum import StrEnum


class MessagingLogEntryOrigin(StrEnum):
    ECOSYSTEM = "ecosystem"
    PLATFORM = "platform"

    def __str__(self) -> str:
        return str(self.value)
