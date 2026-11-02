from enum import StrEnum


class SyncEnrollmentRowScope(StrEnum):
    CUSTOMER = "customer"
    ECOSYSTEM = "ecosystem"

    def __str__(self) -> str:
        return str(self.value)
