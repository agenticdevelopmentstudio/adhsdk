from enum import StrEnum


class GetV1OwnershipItemsKind(StrEnum):
    APPLICATION = "application"
    CUSTOMER = "customer"
    ECOSYSTEM = "ecosystem"
    ORGANIZATION = "organization"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
