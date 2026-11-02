from enum import StrEnum


class ListMemberDeliveryStatus(StrEnum):
    BOUNCED = "bounced"
    COMPLAINED = "complained"
    OK = "ok"
    SUPPRESSED = "suppressed"

    def __str__(self) -> str:
        return str(self.value)
