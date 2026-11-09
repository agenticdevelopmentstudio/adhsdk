from enum import StrEnum


class GetV1ProcessingJobsByIdResponse200Status(StrEnum):
    CLAIMED = "claimed"
    DEAD = "dead"
    QUEUED = "queued"
    SUCCEEDED = "succeeded"

    def __str__(self) -> str:
        return str(self.value)
