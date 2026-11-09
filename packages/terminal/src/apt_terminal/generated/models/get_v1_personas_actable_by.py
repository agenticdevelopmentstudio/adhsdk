from enum import StrEnum


class GetV1PersonasActableBy(StrEnum):
    ME = "me"

    def __str__(self) -> str:
        return str(self.value)
