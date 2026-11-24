from enum import StrEnum


class PostV1ProcessingJobsByIdRetryResponse200Status(StrEnum):
    QUEUED = "queued"

    def __str__(self) -> str:
        return str(self.value)
