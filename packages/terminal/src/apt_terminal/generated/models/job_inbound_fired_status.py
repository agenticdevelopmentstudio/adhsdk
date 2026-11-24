from enum import StrEnum


class JobInboundFiredStatus(StrEnum):
    FAILED = "failed"

    def __str__(self) -> str:
        return str(self.value)
