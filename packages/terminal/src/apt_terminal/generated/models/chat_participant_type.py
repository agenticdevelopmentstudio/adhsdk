from enum import StrEnum


class ChatParticipantType(StrEnum):
    PERSONA = "persona"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
