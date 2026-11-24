from enum import StrEnum


class PostV1OwnershipErasuresBodyKind(StrEnum):
    APPLICATION = "application"
    CUSTOMER = "customer"
    ECOSYSTEM = "ecosystem"
    ORGANIZATION = "organization"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
