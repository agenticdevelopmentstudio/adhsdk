from enum import StrEnum


class PostV1OwnershipHandoversBodyKind(StrEnum):
    CUSTOMER = "customer"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
