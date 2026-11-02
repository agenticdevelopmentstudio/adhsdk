from enum import StrEnum


class PostCommunitiesIdMembersBodyRole(StrEnum):
    ADMIN = "admin"
    MEMBER = "member"
    MODERATOR = "moderator"

    def __str__(self) -> str:
        return str(self.value)
