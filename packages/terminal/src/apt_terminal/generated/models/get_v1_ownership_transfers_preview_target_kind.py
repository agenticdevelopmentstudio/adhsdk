from enum import StrEnum


class GetV1OwnershipTransfersPreviewTargetKind(StrEnum):
    CUSTOMER = "customer"
    ORGANIZATION = "organization"

    def __str__(self) -> str:
        return str(self.value)
