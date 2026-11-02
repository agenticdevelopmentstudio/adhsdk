from enum import StrEnum


class ShiprRunStepState(StrEnum):
    FAILED = "failed"
    PENDING = "pending"
    RUNNING = "running"
    SKIPPED = "skipped"
    SUCCEEDED = "succeeded"

    def __str__(self) -> str:
        return str(self.value)
