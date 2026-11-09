from enum import StrEnum


class PostV1ProjectsByIdParticipantsBodyParticipantKind(StrEnum):
    CUSTOMER = "customer"
    PERSONA = "persona"
    TEAM = "team"

    def __str__(self) -> str:
        return str(self.value)
