from enum import StrEnum


class ChatLiveEventState(StrEnum):
    START = "start"
    STOP = "stop"

    def __str__(self) -> str:
        return str(self.value)
