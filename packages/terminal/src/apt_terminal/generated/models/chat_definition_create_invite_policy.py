from enum import StrEnum


class ChatDefinitionCreateInvitePolicy(StrEnum):
    ANY_PARTICIPANT = "any_participant"
    OWNER = "owner"

    def __str__(self) -> str:
        return str(self.value)
