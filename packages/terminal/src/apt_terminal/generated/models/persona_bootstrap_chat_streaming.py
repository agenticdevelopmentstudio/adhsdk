from enum import StrEnum


class PersonaBootstrapChatStreaming(StrEnum):
    SSE = "sse"

    def __str__(self) -> str:
        return str(self.value)
