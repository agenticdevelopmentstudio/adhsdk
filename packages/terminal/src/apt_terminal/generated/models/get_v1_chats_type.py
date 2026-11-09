from enum import StrEnum


class GetV1ChatsType(StrEnum):
    DIRECT = "direct"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
