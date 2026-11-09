from enum import StrEnum


class GetV1HandlesByHandleResponse200Reason(StrEnum):
    FORMAT = "format"
    TAKEN = "taken"

    def __str__(self) -> str:
        return str(self.value)
