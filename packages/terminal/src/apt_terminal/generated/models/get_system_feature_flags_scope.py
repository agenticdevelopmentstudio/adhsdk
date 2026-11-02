from enum import StrEnum


class GetSystemFeatureFlagsScope(StrEnum):
    SYSTEM = "system"

    def __str__(self) -> str:
        return str(self.value)
