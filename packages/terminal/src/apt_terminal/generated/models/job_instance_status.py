from enum import StrEnum


class JobInstanceStatus(StrEnum):
    ACTIVE = "active"
    ARCHIVED = "archived"
    PAUSED = "paused"

    def __str__(self) -> str:
        return str(self.value)
