from enum import StrEnum


class GetV1OwnershipTransfersPreviewResponse200RevokingItemVia(StrEnum):
    DIRECT = "direct"
    GROUP = "group"
    PARTICIPANT = "participant"
    ROLE = "role"
    TEAM = "team"

    def __str__(self) -> str:
        return str(self.value)
