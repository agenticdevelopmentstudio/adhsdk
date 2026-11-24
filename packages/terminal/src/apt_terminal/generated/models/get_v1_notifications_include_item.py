from enum import StrEnum


class GetV1NotificationsIncludeItem(StrEnum):
    UNREAD_COUNT = "unread_count"

    def __str__(self) -> str:
        return str(self.value)
