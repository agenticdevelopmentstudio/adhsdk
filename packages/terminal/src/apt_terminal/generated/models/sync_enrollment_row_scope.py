from enum import StrEnum


class SyncEnrollmentRowScope(StrEnum):
    CUSTOMER = "customer"
    ECOSYSTEM = "ecosystem"
    OWNER = "owner"

    def __str__(self) -> str:
        return str(self.value)
