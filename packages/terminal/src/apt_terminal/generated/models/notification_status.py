from enum import StrEnum


class NotificationStatus(StrEnum):
    ARCHIVED = "archived"
    INBOX = "inbox"
    TRASHED = "trashed"

    def __str__(self) -> str:
        return str(self.value)
