from enum import StrEnum


class JobInstancePatchStatus(StrEnum):
    ACTIVE = "active"
    PAUSED = "paused"

    def __str__(self) -> str:
        return str(self.value)
