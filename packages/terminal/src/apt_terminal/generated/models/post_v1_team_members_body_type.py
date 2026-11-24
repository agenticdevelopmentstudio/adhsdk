from enum import StrEnum


class PostV1TeamMembersBodyType(StrEnum):
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
