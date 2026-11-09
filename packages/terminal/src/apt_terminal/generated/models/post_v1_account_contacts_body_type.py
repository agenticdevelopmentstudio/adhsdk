from enum import StrEnum


class PostV1AccountContactsBodyType(StrEnum):
    EMAIL = "email"
    PHONE = "phone"

    def __str__(self) -> str:
        return str(self.value)
