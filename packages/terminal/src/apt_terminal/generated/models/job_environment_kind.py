from enum import StrEnum


class JobEnvironmentKind(StrEnum):
    MACHINE = "machine"

    def __str__(self) -> str:
        return str(self.value)
