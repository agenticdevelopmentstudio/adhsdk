from enum import StrEnum


class SyncEnrollmentRowScope(StrEnum):
    AUTHOR = "author"
    ECOSYSTEM = "ecosystem"
    OWNER = "owner"

    def __str__(self) -> str:
        return str(self.value)
