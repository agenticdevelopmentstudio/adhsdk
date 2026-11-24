from enum import StrEnum


class GetV1OwnershipTransfersPreviewResponse200RevokingItemKind(StrEnum):
    APP = "app"
    ORGANIZATION = "organization"
    PERSONA = "persona"
    TEAM = "team"
    TOKEN = "token"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
