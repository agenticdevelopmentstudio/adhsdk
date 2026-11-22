from enum import StrEnum


class SetEffectiveEffectiveType0Error(StrEnum):
    UNRESOLVED = "unresolved"

    def __str__(self) -> str:
        return str(self.value)
