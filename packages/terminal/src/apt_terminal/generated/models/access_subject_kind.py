from enum import StrEnum


class AccessSubjectKind(StrEnum):
    CUSTOMER = "customer"

    def __str__(self) -> str:
        return str(self.value)
