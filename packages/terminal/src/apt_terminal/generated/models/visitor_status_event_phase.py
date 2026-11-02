from enum import StrEnum


class VisitorStatusEventPhase(StrEnum):
    RETRYING = "retrying"

    def __str__(self) -> str:
        return str(self.value)
