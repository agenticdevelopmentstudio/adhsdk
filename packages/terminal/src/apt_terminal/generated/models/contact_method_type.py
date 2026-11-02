from enum import StrEnum


class ContactMethodType(StrEnum):
    EMAIL = "email"
    PHONE = "phone"

    def __str__(self) -> str:
        return str(self.value)
