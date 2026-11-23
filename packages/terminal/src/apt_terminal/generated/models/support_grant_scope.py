from enum import StrEnum


class SupportGrantScope(StrEnum):
    READ_ALL = "read_all"

    def __str__(self) -> str:
        return str(self.value)
