from enum import StrEnum


class PostV1OwnershipTransfersResponse200RevokedSubjectsItemVia(StrEnum):
    DIRECT = "direct"
    GROUP = "group"
    PARTICIPANT = "participant"
    ROLE = "role"
    TEAM = "team"

    def __str__(self) -> str:
        return str(self.value)
