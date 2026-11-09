from enum import StrEnum


class PostV1CommunitiesByIdMembersBodyRole(StrEnum):
    ADMIN = "admin"
    MEMBER = "member"
    MODERATOR = "moderator"

    def __str__(self) -> str:
        return str(self.value)
