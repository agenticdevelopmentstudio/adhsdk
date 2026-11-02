from enum import StrEnum


class SyncPushResultStatus(StrEnum):
    APPLIED = "applied"
    CONFLICT = "conflict"
    REJECTED = "rejected"

    def __str__(self) -> str:
        return str(self.value)
