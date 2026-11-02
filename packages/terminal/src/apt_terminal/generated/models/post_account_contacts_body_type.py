from enum import StrEnum


class PostAccountContactsBodyType(StrEnum):
    EMAIL = "email"
    PHONE = "phone"

    def __str__(self) -> str:
        return str(self.value)
