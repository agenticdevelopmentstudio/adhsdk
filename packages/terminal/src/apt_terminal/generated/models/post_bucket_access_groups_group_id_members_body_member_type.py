from enum import StrEnum


class PostBucketAccessGroupsGroupIdMembersBodyMemberType(StrEnum):
    APP = "app"
    ORGANIZATION = "organization"
    PERSONA = "persona"
    TOKEN = "token"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
