from enum import StrEnum


class ListMemberStatus(StrEnum):
    SUBSCRIBED = "subscribed"
    UNSUBSCRIBED = "unsubscribed"

    def __str__(self) -> str:
        return str(self.value)
