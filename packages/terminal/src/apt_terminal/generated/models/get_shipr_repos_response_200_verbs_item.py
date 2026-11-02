from enum import StrEnum


class GetShiprReposResponse200VerbsItem(StrEnum):
    C = "C"
    D = "D"
    M = "M"
    R = "R"
    U = "U"

    def __str__(self) -> str:
        return str(self.value)
