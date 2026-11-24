from enum import StrEnum


class PostV1OwnershipTransfersBodyTargetKind(StrEnum):
    CUSTOMER = "customer"
    ORGANIZATION = "organization"

    def __str__(self) -> str:
        return str(self.value)
