from enum import StrEnum


class PostV1OwnershipHandoversResponse200Kind(StrEnum):
    CUSTOMER = "customer"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
