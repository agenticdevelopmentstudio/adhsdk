from enum import StrEnum


class ChatTypingRequestState(StrEnum):
    START = "start"
    STOP = "stop"

    def __str__(self) -> str:
        return str(self.value)
