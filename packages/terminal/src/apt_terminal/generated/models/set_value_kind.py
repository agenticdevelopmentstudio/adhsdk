from enum import StrEnum


class SetValueKind(StrEnum):
    LIMIT = "limit"
    PERMISSION = "permission"

    def __str__(self) -> str:
        return str(self.value)
