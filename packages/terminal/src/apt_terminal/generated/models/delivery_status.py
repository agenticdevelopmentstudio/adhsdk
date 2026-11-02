from enum import StrEnum


class DeliveryStatus(StrEnum):
    FAILED = "failed"
    QUEUED = "queued"
    SENDING = "sending"
    SENT = "sent"
    SKIPPED = "skipped"

    def __str__(self) -> str:
        return str(self.value)
