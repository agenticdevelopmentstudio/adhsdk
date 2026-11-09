from enum import StrEnum


class GetV1OwnershipItemsResponse200Kind(StrEnum):
    APPLICATION = "application"
    CUSTOMER = "customer"
    ECOSYSTEM = "ecosystem"
    ORGANIZATION = "organization"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
