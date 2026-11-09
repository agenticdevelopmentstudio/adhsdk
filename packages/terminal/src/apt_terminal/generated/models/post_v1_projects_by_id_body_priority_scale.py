from enum import StrEnum


class PostV1ProjectsByIdBodyPriorityScale(StrEnum):
    NONE = "none"
    STANDARD = "standard"

    def __str__(self) -> str:
        return str(self.value)
