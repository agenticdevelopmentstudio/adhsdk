from enum import StrEnum


class GetAuthSlugAvailableSlugResponse200Reason(StrEnum):
    FORMAT = "format"
    TAKEN = "taken"

    def __str__(self) -> str:
        return str(self.value)
