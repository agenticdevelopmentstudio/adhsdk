from enum import StrEnum


class PostV1OwnershipTransfersResponse200RevokedSubjectsItemKind(StrEnum):
    APP = "app"
    ORGANIZATION = "organization"
    PERSONA = "persona"
    TEAM = "team"
    TOKEN = "token"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
