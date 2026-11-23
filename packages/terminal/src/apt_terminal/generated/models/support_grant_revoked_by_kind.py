from enum import StrEnum


class SupportGrantRevokedByKind(StrEnum):
    GRANTEE = "grantee"
    MANAGER = "manager"
    OPERATOR = "operator"
    SYSTEM = "system"
    TARGET = "target"

    def __str__(self) -> str:
        return str(self.value)
