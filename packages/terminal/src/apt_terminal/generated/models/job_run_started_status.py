from enum import StrEnum


class JobRunStartedStatus(StrEnum):
    FAILED = "failed"
    RUNNING = "running"

    def __str__(self) -> str:
        return str(self.value)
