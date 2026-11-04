from enum import StrEnum


class PostOwnershipHandoverResponse200Kind(StrEnum):
    CUSTOMER = "customer"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
