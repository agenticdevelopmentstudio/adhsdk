from enum import StrEnum


class GetFriendsRequestsDirection(StrEnum):
    RECEIVED = "received"
    SENT = "sent"

    def __str__(self) -> str:
        return str(self.value)
