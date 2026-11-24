from enum import StrEnum


class GetV1NotificationsStatus(StrEnum):
    ARCHIVED = "archived"
    INBOX = "inbox"
    TRASHED = "trashed"

    def __str__(self) -> str:
        return str(self.value)
