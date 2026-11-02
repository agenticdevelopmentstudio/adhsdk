from enum import StrEnum


class ShiprRunEventStream(StrEnum):
    ERR = "err"
    META = "meta"
    OUT = "out"

    def __str__(self) -> str:
        return str(self.value)
