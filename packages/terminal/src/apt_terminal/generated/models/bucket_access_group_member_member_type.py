from enum import StrEnum


class BucketAccessGroupMemberMemberType(StrEnum):
    APP = "app"
    ORGANIZATION = "organization"
    PERSONA = "persona"
    TOKEN = "token"
    USER = "user"

    def __str__(self) -> str:
        return str(self.value)
