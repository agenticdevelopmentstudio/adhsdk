from enum import StrEnum


class PostV1ChatsBodyType(StrEnum):
    DIRECT = "direct"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
