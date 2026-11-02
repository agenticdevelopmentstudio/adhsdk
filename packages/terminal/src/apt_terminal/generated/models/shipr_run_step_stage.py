from enum import StrEnum


class ShiprRunStepStage(StrEnum):
    ADVANCE = "advance"
    ARRIVAL = "arrival"
    VERIFY = "verify"

    def __str__(self) -> str:
        return str(self.value)
