from enum import StrEnum


class SyncEnrollmentRowPushMode(StrEnum):
    GENERIC = "generic"
    ROUTE = "route"

    def __str__(self) -> str:
        return str(self.value)
