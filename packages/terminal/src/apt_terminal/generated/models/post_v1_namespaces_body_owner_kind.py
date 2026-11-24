from enum import StrEnum


class PostV1NamespacesBodyOwnerKind(StrEnum):
    CUSTOMER = "customer"
    ECOSYSTEM = "ecosystem"
    ORGANIZATION = "organization"
    PERSONA = "persona"

    def __str__(self) -> str:
        return str(self.value)
