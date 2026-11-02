from enum import StrEnum


class CampaignStatus(StrEnum):
    CANCELLED = "cancelled"
    DRAFT = "draft"
    FAILED = "failed"
    SCHEDULED = "scheduled"
    SENDING = "sending"
    SENT = "sent"

    def __str__(self) -> str:
        return str(self.value)
