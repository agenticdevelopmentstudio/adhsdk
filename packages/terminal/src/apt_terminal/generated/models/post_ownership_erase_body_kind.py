from enum import StrEnum


class PostOwnershipEraseBodyKind(StrEnum):
    APPLICATION = "application"
    CUSTOMER = "customer"
    ECOSYSTEM = "ecosystem"
    ORGANIZATION = "organization"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
