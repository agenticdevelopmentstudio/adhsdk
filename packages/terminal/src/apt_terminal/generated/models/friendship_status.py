from enum import StrEnum


class FriendshipStatus(StrEnum):
    ACCEPTED = "accepted"
    DECLINED = "declined"
    PENDING = "pending"

    def __str__(self) -> str:
        return str(self.value)
