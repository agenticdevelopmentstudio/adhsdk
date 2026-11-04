from enum import StrEnum


class ChatDefinitionUpdatePersonaReplyPolicy(StrEnum):
    EVERY_MESSAGE = "every_message"
    WHEN_MENTIONED = "when_mentioned"

    def __str__(self) -> str:
        return str(self.value)
