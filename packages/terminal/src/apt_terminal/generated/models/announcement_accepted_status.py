from enum import StrEnum


class AnnouncementAcceptedStatus(StrEnum):
    SENDING = "sending"

    def __str__(self) -> str:
        return str(self.value)
