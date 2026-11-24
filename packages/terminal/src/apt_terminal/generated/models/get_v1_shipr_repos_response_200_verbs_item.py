from enum import StrEnum


class GetV1ShiprReposResponse200VerbsItem(StrEnum):
    C = "C"
    D = "D"
    M = "M"
    R = "R"
    U = "U"

    def __str__(self) -> str:
        return str(self.value)
