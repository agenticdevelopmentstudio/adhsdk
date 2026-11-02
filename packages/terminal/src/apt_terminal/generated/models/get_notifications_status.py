from enum import StrEnum


class GetNotificationsStatus(StrEnum):
    ARCHIVED = "archived"
    INBOX = "inbox"
    TRASHED = "trashed"

    def __str__(self) -> str:
        return str(self.value)
