from enum import StrEnum


class PostV1BucketAccessGroupsByIdMembersBodyMemberType(StrEnum):
    APP = "app"
    ORGANIZATION = "organization"
    PERSONA = "persona"
    TOKEN = "token"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
