from enum import StrEnum


class GetV1FriendRequestsDirection(StrEnum):
    RECEIVED = "received"
    SENT = "sent"

    def __str__(self) -> str:
        return str(self.value)
