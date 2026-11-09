from enum import StrEnum


class GetV1ContentFeedItemsIncludeItem(StrEnum):
    UNREAD_COUNT = "unread_count"

    def __str__(self) -> str:
        return str(self.value)
