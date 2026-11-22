from enum import StrEnum


class CustomerMeSetsType0Error(StrEnum):
    UNRESOLVED = "unresolved"

    def __str__(self) -> str:
        return str(self.value)
