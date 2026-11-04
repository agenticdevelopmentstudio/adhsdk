from enum import StrEnum


class ChatType(StrEnum):
    DM = "dm"
    GROUP = "group"

    def __str__(self) -> str:
        return str(self.value)
