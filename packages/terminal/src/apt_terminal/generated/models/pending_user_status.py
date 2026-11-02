from enum import StrEnum


class PendingUserStatus(StrEnum):
    ACCEPTED = "accepted"
    DECLINED = "declined"
    INVITED = "invited"
    PENDING = "pending"

    def __str__(self) -> str:
        return str(self.value)
