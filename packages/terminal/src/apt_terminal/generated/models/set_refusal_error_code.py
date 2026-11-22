from enum import StrEnum


class SetRefusalErrorCode(StrEnum):
    SET_REFUSED = "set_refused"

    def __str__(self) -> str:
        return str(self.value)
