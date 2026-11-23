from enum import StrEnum


class SupportGrantGranteeKind(StrEnum):
    OPERATOR = "operator"
    PRODUCT_ADMIN = "product_admin"

    def __str__(self) -> str:
        return str(self.value)
